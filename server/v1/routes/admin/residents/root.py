from __future__ import annotations

from typing import Annotated, List, Literal, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, Resident, Result
from .....config import DB_PAGINATION_QUERY


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
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    offset: int = 0,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
    order_by: Literal["id", "name", "room", "username"] = "id",
    ascending: bool = True,
) -> Result[Optional[List[Resident]]]:
    if admin.admin:
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

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
