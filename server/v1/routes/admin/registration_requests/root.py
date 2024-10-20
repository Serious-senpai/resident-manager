from __future__ import annotations

from typing import List, Literal, Optional

from fastapi import Response, status

from ....app import api_v1
from ....models import AuthorizationHeader, RegisterRequest, Result
from .....config import DB_PAGINATION_QUERY


__all__ = ("admin_reg_request",)


@api_v1.get(
    "/admin/registration-requests",
    name="Registration requests query",
    description=f"Query a maximum of {DB_PAGINATION_QUERY} registration requests from the specified offset",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "List of registration requests",
            "model": Result[List[RegisterRequest]],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def admin_reg_request(
    headers: AuthorizationHeader,
    response: Response,
    offset: int = 0,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
    order_by: Literal["request_id", "name", "room", "username"] = "request_id",
    ascending: bool = True,
) -> Result[Optional[List[RegisterRequest]]]:
    auth = await headers.verify_admin()
    if auth is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return auth

    return Result(
        data=await RegisterRequest.query(
            offset=offset,
            id=id,
            name=name,
            room=room,
            username=username,
            order_by=order_by,
            ascending=ascending,
        ),
    )
