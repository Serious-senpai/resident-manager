from __future__ import annotations

from typing import Optional

from fastapi import Response, status

from .....app import api_v1
from .....models import AuthorizationHeader, Resident, Result


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

    return Result(data=await Resident.count(id=id, name=name, room=room, username=username))
