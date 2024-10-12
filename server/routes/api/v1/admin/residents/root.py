from __future__ import annotations

from typing import List, Literal, Optional

from fastapi import Response, status

from ......apps import api_v1
from ......config import DB_PAGINATION_QUERY
from ......models import Authorization, AuthorizationHeader, Resident, Result


__all__ = ("admin_residents",)


@api_v1.get(
    "/admin/residents",
    name="Residents query",
    description=f"Query a maximum of {DB_PAGINATION_QUERY} registration requests from the specified offset",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "List of residents objects",
            "model": Result[List[Resident]],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def admin_residents(
    headers: AuthorizationHeader,
    response: Response,
    offset: int = 0,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
    order_by: Literal["resident_id", "name", "room", "username"] = "resident_id",
    ascending: bool = True,
) -> Result[Optional[List[Resident]]]:
    auth = await Authorization.verify_admin_headers(headers)
    if auth is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return auth

    return Result(
        data=await Resident.query(
            offset=offset,
            id=id,
            name=name,
            room=room,
            username=username,
            order_by=order_by,
            ascending=ascending,
        ),
    )
