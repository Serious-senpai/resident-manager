from __future__ import annotations

from typing import List, Optional

from fastapi import Response, status

from ....app import api_v1
from ....models import AuthorizationHeader, Result, RoomData


__all__ = ("admin_rooms_delete",)


@api_v1.post(
    "/admin/rooms/delete",
    name="Room information deletion",
    description="Delete room information",
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
async def admin_rooms_delete(
    headers: AuthorizationHeader,
    response: Response,
    rooms: List[int],
) -> Optional[Result[None]]:
    auth = await headers.verify_admin()
    if auth is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return auth

    await RoomData.delete_many(rooms)
    return None
