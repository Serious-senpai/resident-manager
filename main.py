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

from server import api_router, Database


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
    lifespan=ApplicationLifespan,
)
app.include_router(api_router)


@app.get("/", include_in_schema=False)
async def root() -> RedirectResponse:
    """Redirect to API documentation"""
    return RedirectResponse("/docs")
