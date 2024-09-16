from __future__ import annotations

from aiohttp import web

from ...router import api_router


@api_router.get("/login")
async def login(request: web.Request) -> web.Response:
    raise web.HTTPForbidden
