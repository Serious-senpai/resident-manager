from __future__ import annotations

from aiohttp import web

from ...router import root_router


@root_router.get("/")
async def root(request: web.Request) -> web.Response:
    user_agent = request.headers.get("User-Agent", "Unknown")
    remote = request.remote
    return web.json_response({"user_agent": user_agent, "remote": remote})
