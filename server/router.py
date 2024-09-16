from __future__ import annotations

from aiohttp import web


__all__ = (
    "api_router",
    "root_router",
)


api_router = web.RouteTableDef()
root_router = web.RouteTableDef()
