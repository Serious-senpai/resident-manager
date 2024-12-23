from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from pathlib import Path
from typing import AsyncGenerator

from fastapi import FastAPI
from fastapi.responses import RedirectResponse
from fastapi.staticfiles import StaticFiles


__all__ = (
    "api_v1",
)
logger = logging.getLogger("uvicorn")


@asynccontextmanager
async def __lifespan(app: FastAPI) -> AsyncGenerator[None]:
    logger.info(f"Starting {app} from {__file__}")
    yield
    logger.info(f"Stopping {app} from {__file__}")


current_dir = Path(__file__).parent
readme = current_dir.parent.parent / "README.md"
with readme.open("r", encoding="utf-8") as f:
    description = f.read()


api_v1 = FastAPI(
    title="Resident manager API v1",
    description=description,
    version="1.0.0",
    lifespan=__lifespan,
)
api_v1.mount("/static", StaticFiles(directory=current_dir / "static"))


@api_v1.get("/", include_in_schema=False)
async def root() -> RedirectResponse:
    return RedirectResponse("/api/v1/static/index.html")
