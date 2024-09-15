from __future__ import annotations

from aiohttp import web


routes = web.RouteTableDef()


@routes.get("/")
async def hello(request: web.Request) -> web.Response:
    user_agent = request.headers.get("User-Agent")
    if user_agent is None:
        raise web.HTTPForbidden

    return web.Response(text=user_agent)


app = web.Application()
app.add_routes(routes)
web.run_app(app)
