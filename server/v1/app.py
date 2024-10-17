from __future__ import annotations

from contextlib import AbstractAsyncContextManager
from pathlib import Path
from types import TracebackType
from typing import Optional, Final, Type, TYPE_CHECKING

from fastapi import FastAPI

from .database import Database


__all__ = (
    "api_v1",
)


class _ApplicationLifespan(AbstractAsyncContextManager):

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
    ) -> None:
        await Database.instance.close()


readme = Path(__file__).parent.parent.parent / "README.md"
with readme.open("r", encoding="utf-8") as f:
    description = f.read()


api_v1 = FastAPI(
    title="Apartment management API v1",
    description=description,
    version="1.0.0",
    lifespan=_ApplicationLifespan,
)
