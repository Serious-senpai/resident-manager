from __future__ import annotations

from typing import Annotated, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, RegisterRequest, Result


__all__ = ("admin_reg_request_count",)


@api_v1.get(
    "/admin/registration-requests/count",
    name="Registration requests count",
    description="Return number of registration requests",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "Number of registration requests",
            "model": Result[int],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_200_OK,
)
async def admin_reg_request_count(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
) -> Result[Optional[int]]:
    if admin.admin:
        return Result(
            data=await RegisterRequest.count(
                id=id,
                name=name,
                room=room,
                username=username,
            ),
        )

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
