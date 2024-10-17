from __future__ import annotations

from typing import List, Optional

from fastapi import Response, status

from .....app import api_v1
from .....models import AuthorizationHeader, Result, Room
from ......config import DB_PAGINATION_QUERY


__all__ = ("admin_rooms",)


@api_v1.get(
    "/admin/rooms",
    name="Room information query",
    description=f"Query a maximum of {DB_PAGINATION_QUERY} room information from the specified offset",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "List of room objects",
            "model": Result[List[Room]],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def admin_rooms(
    headers: AuthorizationHeader,
    response: Response,
    offset: int,
    room: Optional[int] = None,
    floor: Optional[int] = None,
) -> Result[Optional[List[Room]]]:
    auth = await headers.verify_admin()
    if auth is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return auth

    return Result(data=await Room.query(offset=offset, room=room, floor=floor))
