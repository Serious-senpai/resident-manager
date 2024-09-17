from __future__ import annotations

from aiohttp import web

from ...encoder import dumps
from ...residents import Resident
from ...router import api_router
from ...utils import error_message


# https://stackoverflow.com/a/7562744
@api_router.post("/login")
async def login(request: web.Request) -> web.Response:
    try:
        username = request.headers["Username"]
        password = request.headers["Password"]
    except KeyError:
        return error_message("Missing required headers", status=400)

    resident = await Resident.from_username(username)
    if resident is None:
        return error_message(f"No resident with username \"{username}\"", status=404)

    if password != resident.hashed_password:
        return error_message("Incorrect password", status=403)

    return web.json_response({"resident": resident}, dumps=dumps)
