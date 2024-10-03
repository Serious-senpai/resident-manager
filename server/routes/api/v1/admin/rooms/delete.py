from __future__ import annotations

from typing import List

from fastapi import status

from ......apps import api_v1
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import AuthorizationHeader, Room


__all__ = ("admin_rooms_delete",)


@api_v1.post(
    "/admin/rooms/delete",
    name="Room information deletion",
    description="Update room information",
    tags=["admin"],
    response_model=None,
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_rooms_delete(
    headers: AuthorizationHeader,
    rooms: List[int],
) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    await Room.delete_many(rooms)
