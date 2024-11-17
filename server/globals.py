from __future__ import annotations

import asyncio
import logging
from collections import OrderedDict
from contextlib import AbstractAsyncContextManager
from types import TracebackType
from typing import Dict, Final, Optional, Type, TYPE_CHECKING

from fastapi import FastAPI, Request
from fastapi.responses import RedirectResponse

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
