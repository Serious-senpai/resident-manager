from __future__ import annotations

import fastapi


__all__ = (
    "api_v1",
)


api_v1 = fastapi.FastAPI(
    title="Apartment management API v1",
    description="REST API for apartment management application",
)
