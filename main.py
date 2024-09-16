from __future__ import annotations

import asyncio

from aiohttp import web
try:
    import uvloop  # type: ignore
except ImportError:
    pass
else:
    asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

import server.routes  # noqa: F401  # Import route handlers
from server import PORT, api_router, root_router


if __name__ == "__main__":
    app = web.Application()
    app.add_routes(root_router)

    api = web.Application()
    api.add_routes(api_router)
    app.add_subapp("/api", api)

    web.run_app(app, port=PORT)
