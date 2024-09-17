from __future__ import annotations

from aiohttp import web

from ...router import api_router


@api_router.get("")
@api_router.get("/")
async def root(request: web.Request) -> web.Response:
    raise web.HTTPFound("/")
