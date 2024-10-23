from __future__ import annotations

from typing import Annotated, List, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, Result, Room
from .....config import DB_PAGINATION_QUERY


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
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    offset: int,
    room: Optional[int] = None,
    floor: Optional[int] = None,
) -> Result[Optional[List[Room]]]:
    if admin.admin:
        return Result(data=await Room.query(offset=offset, room=room, floor=floor))

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
