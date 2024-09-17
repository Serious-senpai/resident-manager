from __future__ import annotations

from datetime import timedelta

from aiohttp import web

from ...auth import hash_password
from ...reg_request import RegisterRequest
from ...router import api_router
from ...utils import error_message, from_epoch


@api_router.post("/register")
async def register(request: web.Request) -> web.Response:
    try:
        username = request.headers["Username"]
        password = request.headers["Password"]
    except KeyError:
        return error_message("Missing required headers", status=400)

    try:
        name = request.query["name"]
        room = int(request.query["room"])
        birthday = from_epoch(timedelta(days=int(request.query["birthday"])))
        phone = request.query.get("phone")
        email = request.query.get("email")
    except KeyError:
        return error_message("Missing required query parameters", status=400)

    await RegisterRequest.create(
        name=name,
        room=room,
        birthday=birthday,
        phone=phone,
        email=email,
        username=username,
        hashed_password=hash_password(password),
    )

    return web.Response(status=203)
