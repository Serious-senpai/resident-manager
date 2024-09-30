from __future__ import annotations

from fastapi import status

from ......apps import api_v1
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import AuthorizationHeader, Room


__all__ = ("admin_rooms_count",)


@api_v1.get(
    "/admin/rooms/count",
    name="Rooms count",
    description="Return number of rooms",
    tags=["admin"],
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_200_OK,
)
async def admin_rooms_count(headers: AuthorizationHeader) -> int:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    return await Room.count()
