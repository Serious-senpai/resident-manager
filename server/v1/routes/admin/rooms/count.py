from __future__ import annotations

from typing import Annotated, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, Result, Room


__all__ = ("admin_rooms_count",)


@api_v1.get(
    "/admin/rooms/count",
    name="Rooms count",
    description="Return number of rooms",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "Return number of rooms",
            "model": Result[int],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def admin_rooms_count(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    room: Optional[int] = None,
    floor: Optional[int] = None,
) -> Result[Optional[int]]:
    if admin.admin:
        return Result(data=await Room.count(room=room, floor=floor))

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
