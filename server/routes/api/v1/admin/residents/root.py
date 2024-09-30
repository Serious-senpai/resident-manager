from __future__ import annotations

from typing import List, Literal, Optional

from fastapi import status

from ......apps import api_v1
from ......config import DB_PAGINATION_QUERY
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import AuthorizationHeader, Resident


__all__ = ("admin_residents",)


@api_v1.get(
    "/admin/residents",
    name="Residents query",
    description=f"Query a maximum of {DB_PAGINATION_QUERY} registration requests from the specified offset",
    tags=["admin"],
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_200_OK,
)
async def admin_residents(
    headers: AuthorizationHeader,
    offset: int = 0,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
    order_by: Literal["resident_id", "name", "room", "username"] = "resident_id",
    ascending: bool = True,
) -> List[Resident]:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    return await Resident.query(
        offset=offset,
        id=id,
        name=name,
        room=room,
        username=username,
        order_by=order_by,
        ascending=ascending,
    )
