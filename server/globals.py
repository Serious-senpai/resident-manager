from __future__ import annotations

import hashlib
import hmac
import asyncio
import logging
import urllib.parse
from collections import OrderedDict
from contextlib import AsyncExitStack, asynccontextmanager
from typing import AsyncGenerator, Dict, Optional

from fastapi import FastAPI, Request
from pydantic import BaseModel
from fastapi.responses import RedirectResponse

from .config import VNPAY_SECRET_KEY, VNPAY_TMN_CODE
from .database import Database


try:
    import coverage  # dev-dependency only
except ImportError:
    pass

try:
    import uvloop  # type: ignore
except ImportError:
    pass
else:
    asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

from .config import CI
from .v1 import api_v1


__all__ = ("global_app",)


logger = logging.getLogger("uvicorn")
subapps: OrderedDict[str, FastAPI] = OrderedDict()
subapps["/api/v1"] = api_v1

final_subroute = list(subapps.keys())[-1]
final_subapp = list(subapps.values())[-1]


@asynccontextmanager
async def __lifespan(app: FastAPI) -> AsyncGenerator[None]:
    cov: Optional[coverage.Coverage] = None
    if CI:
        cov = coverage.Coverage(data_suffix=True, config_file=True)
        cov.start()
        logger.info("Measuring code coverage...")

    logger.info(f"Starting {app} from {__file__}")
    await Database.instance.prepare()
    async with AsyncExitStack() as stack:
        for subapp in subapps.values():
            await stack.enter_async_context(subapp.router.lifespan_context(subapp))

        yield

    logger.info(f"Stopping {app} from {__file__}")
    await Database.instance.close()
    if cov is not None:
        cov.stop()
        cov.save()


global_app = FastAPI(
    title="Resident manager API",
    docs_url=None,
    redoc_url=None,
    lifespan=__lifespan,
    version=final_subapp.version,
)
for route, subapp in subapps.items():
    global_app.mount(route, subapp)


@global_app.get("/", include_in_schema=False)
async def root() -> RedirectResponse:
    """Redirect to API documentation of latest version"""
    return RedirectResponse(final_subroute)


@global_app.get("/loop", include_in_schema=False)
async def loop() -> str:
    """Return current asyncio event loop"""
    return str(asyncio.get_event_loop())


@global_app.get("/headers", include_in_schema=False)
async def headers(request: Request) -> Dict[str, str]:
    """Echo client headers"""
    return dict(request.headers)


@global_app.get("/docs", include_in_schema=False)
async def docs() -> RedirectResponse:
    """Redirect to API documentation of latest version"""
    return RedirectResponse(final_subroute + "/docs")


@global_app.get("/redoc", include_in_schema=False)
async def redoc() -> RedirectResponse:
    """Redirect to API documentation of latest version"""
    return RedirectResponse(final_subroute + "/redoc")


class _VNPayResponse(BaseModel):
    RspCode: str
    Message: str


@global_app.get("/ipn", include_in_schema=False)
async def ipn(request: Request) -> _VNPayResponse:
    params = dict(sorted(request.query_params.items()))

    # Validate request parameters
    try:
        vnp_securehash = params.pop("vnp_SecureHash")
        vnp_tmncode = params["vnp_TmnCode"]
    except KeyError:
        return _VNPayResponse(RspCode="99", Message="Missing required fields")

    data = "&".join(f"{k}={urllib.parse.quote_plus(str(v))}" for k, v in params.items())
    expected_checksum = hmac.new(
        VNPAY_SECRET_KEY.encode("utf-8"),
        data.encode("utf-8"),
        digestmod=hashlib.sha512,
    ).hexdigest()
    if VNPAY_TMN_CODE != vnp_tmncode or vnp_securehash != expected_checksum:
        return _VNPayResponse(RspCode="97", Message="Invalid signature")

    try:
        vnp_responsecode = params["vnp_ResponseCode"]
        vnp_txnref = params["vnp_TxnRef"]
    except KeyError:
        return _VNPayResponse(RspCode="99", Message="Missing required fields")

    room, fee_id, normalized_amount, _ = map(int, vnp_txnref.split("-"))

    try:
        vnp_amount = int(params["vnp_Amount"])
    except KeyError:
        return _VNPayResponse(RspCode="99", Message="Missing required fields")

    if vnp_amount != normalized_amount:
        return _VNPayResponse(RspCode="04", Message="Invalid amount")

    # Update database
    if vnp_responsecode in {"00", "07"}:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "EXECUTE CreatePayment @Room = ?, @Amount = ?, @FeeId = ?",
                    room,
                    normalized_amount,
                    fee_id,
                )

                row = await cursor.fetchone()
                if row is not None:
                    return _VNPayResponse(RspCode=row.code, Message=row.message)

    return _VNPayResponse(RspCode="00", Message="Unknown state, payment may not be updated")
