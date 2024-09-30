from __future__ import annotations

from typing import Annotated, List, Optional

from fastapi import Header, status

from ......apps import api_v1
from ......config import DB_PAGINATION_QUERY
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import Authorization, RegisterRequest


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
    headers: Annotated[Authorization, Header()],
    offset: int = 0,
    id: Optional[int] = None,
    name: Optional[str] = None,
    room: Optional[int] = None,
    username: Optional[str] = None,
) -> List[RegisterRequest]:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    return await RegisterRequest.query(offset=offset, id=id, name=name, room=room, username=username)
