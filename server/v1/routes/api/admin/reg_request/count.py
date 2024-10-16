from __future__ import annotations

from typing import Optional

from fastapi import Response, status

from .....apps import api_v1
from .....models import AuthorizationHeader, RegisterRequest, Result


__all__ = ("admin_reg_request_count",)


@api_v1.get(
    "/admin/reg-request/count",
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
    headers: AuthorizationHeader,
    response: Response,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
) -> Result[Optional[int]]:
    auth = await headers.verify_admin()
    if auth is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return auth

    return Result(
        data=await RegisterRequest.count(
            id=id,
            name=name,
            room=room,
            username=username,
        ),
    )
