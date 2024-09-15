from __future__ import annotations

from aiohttp import web

from src import PORT


routes = web.RouteTableDef()


@routes.get("/")
async def hello(request: web.Request) -> web.Response:
    user_agent = request.headers.get("User-Agent")
    if user_agent is None:
        raise web.HTTPForbidden

    return web.Response(text=user_agent)


if __name__ == "__main__":
    app = web.Application()
    app.add_routes(routes)

    web.run_app(app, port=PORT)
