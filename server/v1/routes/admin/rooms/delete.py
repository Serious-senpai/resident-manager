from __future__ import annotations

from typing import Annotated, List, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, Result, RoomData


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
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    rooms: List[int],
) -> Optional[Result[None]]:
    if admin.admin:
        await RoomData.delete_many(rooms)
        return None

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
