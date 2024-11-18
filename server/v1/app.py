from __future__ import annotations

from contextlib import AbstractAsyncContextManager
from pathlib import Path
from types import TracebackType
from typing import Optional, Final, Type, TYPE_CHECKING

from fastapi import FastAPI
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles

from ..database import Database


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


current_dir = Path(__file__).parent
readme = current_dir.parent.parent / "README.md"
with readme.open("r", encoding="utf-8") as f:
    description = f.read()


api_v1 = FastAPI(
    title="Resident manager API v1",
    description=description,
    version="1.0.0",
    lifespan=_ApplicationLifespan,
)
api_v1.mount("/static", StaticFiles(directory=current_dir / "static"))


index = current_dir / "index.html"
with index.open("r", encoding="utf-8") as f:
    index_html = f.read()


@api_v1.get("/", include_in_schema=False)
async def root() -> HTMLResponse:
    return HTMLResponse(index_html)
