from __future__ import annotations

from typing import Annotated, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, Resident, Result


__all__ = ("admin_residents_count",)


@api_v1.get(
    "/admin/residents/count",
    name="Residents count",
    description="Return number of residents",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "Return number of residents",
            "model": Result[int],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def admin_residents_count(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
) -> Result[Optional[int]]:
    if admin.admin:
        return Result(data=await Resident.count(id=id, name=name, room=room, username=username))

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
