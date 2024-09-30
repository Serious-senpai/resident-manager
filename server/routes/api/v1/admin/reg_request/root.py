from __future__ import annotations

from typing import List, Literal, Optional

from fastapi import status

from ......apps import api_v1
from ......config import DB_PAGINATION_QUERY
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import AuthorizationHeader, RegisterRequest


__all__ = ("admin_reg_request",)


@api_v1.get(
    "/admin/reg-request",
    name="Registration requests query",
    description=f"Query a maximum of {DB_PAGINATION_QUERY} registration requests from the specified offset",
    tags=["admin"],
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_200_OK,
)
async def admin_reg_request(
    headers: AuthorizationHeader,
    offset: int = 0,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
    order_by: Literal["request_id", "name", "room", "username"] = "request_id",
    ascending: bool = True,
) -> List[RegisterRequest]:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    return await RegisterRequest.query(
        offset=offset,
        id=id,
        name=name,
        room=room,
        username=username,
        order_by=order_by,
        ascending=ascending,
    )
