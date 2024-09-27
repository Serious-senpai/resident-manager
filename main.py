from __future__ import annotations

import asyncio
from contextlib import AbstractAsyncContextManager
from types import TracebackType
from typing import Final, Optional, Type, TYPE_CHECKING

from fastapi import FastAPI
from fastapi.responses import RedirectResponse
try:
    import uvloop  # type: ignore
except ImportError:
    pass
else:
    asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

from server import api_v1, Database


class ApplicationLifespan(AbstractAsyncContextManager):

    __slots__ = ("app",)
    if TYPE_CHECKING:
        app: Final[FastAPI]

    def __init__(self, app: FastAPI) -> None:
        self.app = app

    async def __aenter__(self) -> None:
        await Database.instance.prepare()

    async def __aexit__(
        self,
        exc_type: Optional[Type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[TracebackType],
    ) -> bool:
        await Database.instance.close()
        return True


app = FastAPI(
    title="Apartment management API",
    description="REST API for apartment management application",
    docs_url=None,
    redoc_url=None,
    lifespan=ApplicationLifespan,
)
app.mount("/api/v1", api_v1)


@app.get("/", include_in_schema=False)
async def root() -> RedirectResponse:
    """Redirect to API documentation"""
    return RedirectResponse("/api/v1/docs")


@app.get("/docs", include_in_schema=False)
async def docs() -> RedirectResponse:
    """Redirect to API documentation"""
    return RedirectResponse("/api/v1/docs")


@app.get("/redoc", include_in_schema=False)
async def redoc() -> RedirectResponse:
    """Redirect to API documentation"""
    return RedirectResponse("/api/v1/redoc")
