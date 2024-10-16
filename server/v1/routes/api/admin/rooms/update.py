from __future__ import annotations

from typing import List, Optional

from fastapi import Response, status

from .....apps import api_v1
from .....models import AuthorizationHeader, Result, RoomData


__all__ = ("admin_rooms_update",)


@api_v1.post(
    "/admin/rooms/update",
    name="Room information update",
    description="Update room information",
    tags=["admin"],
    response_model=None,
    responses={
        status.HTTP_204_NO_CONTENT: {
            "description": "Operation completed successfully",
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_rooms_update(
    headers: AuthorizationHeader,
    response: Response,
    rooms: List[RoomData],
) -> Optional[Result[None]]:
    auth = await headers.verify_admin()
    if auth is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return auth

    await RoomData.update_many(rooms)
    return None
