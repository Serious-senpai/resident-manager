from __future__ import annotations

import fastapi


__all__ = (
    "api_router",
)


api_router = fastapi.APIRouter(prefix="/api")
