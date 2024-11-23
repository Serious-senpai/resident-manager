from __future__ import annotations

import hashlib
import hmac
import asyncio
import logging
import urllib.parse
from collections import OrderedDict
from contextlib import AbstractAsyncContextManager
from types import TracebackType
from typing import Dict, Final, Optional, Type, TYPE_CHECKING

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


class ApplicationLifespan(AbstractAsyncContextManager):

    __slots__ = ("app", "cov")
    if TYPE_CHECKING:
        app: Final[FastAPI]
        cov: Optional[coverage.Coverage]

    def __init__(self, app: FastAPI) -> None:
        self.app = app

        self.cov = None
        if CI:
            self.cov = coverage.Coverage(data_suffix=True, config_file=True)
            self.cov.start()
            logger.info("Measuring code coverage...")

    async def __aenter__(self) -> None:
        coros = [a.router.lifespan_context(subapp).__aenter__() for a in subapps.values()]
        await asyncio.gather(*coros)

    async def __aexit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType],
    ) -> None:
        if self.cov is not None:
            self.cov.stop()
            self.cov.save()

        coros = [a.router.lifespan_context(subapp).__aexit__(exc_type, exc_val, exc_tb) for a in subapps.values()]
        await asyncio.gather(*coros)


global_app = FastAPI(
    title="Resident manager API",
    docs_url=None,
    redoc_url=None,
    lifespan=ApplicationLifespan,
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
        checksum = params.pop("vnp_SecureHash")
        tmn_code = params["vnp_TmnCode"]
    except KeyError:
        return _VNPayResponse(RspCode="99", Message="Missing required fields")

    data = "&".join(f"{k}={urllib.parse.quote_plus(str(v))}" for k, v in params.items())
    expected_checksum = hmac.new(
        VNPAY_SECRET_KEY.encode("utf-8"),
        data.encode("utf-8"),
        digestmod=hashlib.sha512,
    ).hexdigest()
    if VNPAY_TMN_CODE != tmn_code or checksum != expected_checksum:
        return _VNPayResponse(RspCode="97", Message="Invalid signature")

    # Update database
    try:
        response_code = params["vnp_ResponseCode"]
        txn_ref = params["vnp_TxnRef"]
    except KeyError:
        return _VNPayResponse(RspCode="99", Message="Missing required fields")

    if response_code in {"00", "07"}:
        room, fee_id, normalized_amount, _ = map(int, txn_ref.split("-"))
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "EXECUTE CreatePayment @Room = ?, @Amount = ?, @FeeId = ?",
                    room,
                    normalized_amount,
                    fee_id,
                )
                row = await cursor.fetchone()
                if row is None:
                    return _VNPayResponse(RspCode="02", Message="Data has been updated already")

    return _VNPayResponse(RspCode="00", Message="Data has been updated successfully")
