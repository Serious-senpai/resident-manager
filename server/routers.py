from __future__ import annotations

import fastapi


__all__ = (
    "authorization_router",
)


authorization_router = fastapi.APIRouter(
    prefix="/api",
    tags=["authorization"],
)
redirect_router = fastapi.APIRouter
