from __future__ import annotations

import asyncio
import logging
from contextlib import AbstractAsyncContextManager
from types import TracebackType
from typing import Final, Optional, Type, TYPE_CHECKING

from fastapi import FastAPI
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

from server import api_v1, CI


logger = logging.getLogger(__name__)
subapps = {
    "/api/v1": api_v1
}


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


app = FastAPI(
    docs_url=None,
    redoc_url=None,
    lifespan=ApplicationLifespan,
)
for route, subapp in subapps.items():
    app.mount(route, subapp)


@app.get("/", include_in_schema=False)
async def root() -> RedirectResponse:
    """Redirect to API documentation"""
    return RedirectResponse("/api/v1/docs")


@app.get("/loop", include_in_schema=False)
async def loop() -> str:
    """Return current asyncio event loop"""
    return str(asyncio.get_event_loop())


@app.get("/docs", include_in_schema=False)
async def docs() -> RedirectResponse:
    """Redirect to API documentation"""
    return RedirectResponse("/api/v1/docs")


@app.get("/redoc", include_in_schema=False)
async def redoc() -> RedirectResponse:
    """Redirect to API documentation"""
    return RedirectResponse("/api/v1/redoc")
