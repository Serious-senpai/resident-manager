from __future__ import annotations

from typing import List

from fastapi import status

from ......apps import api_v1
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import AuthorizationHeader, Room


__all__ = ("admin_rooms_update",)


@api_v1.post(
    "/admin/rooms/update",
    name="Room information update",
    description="Update room information",
    tags=["admin"],
    response_model=None,
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_rooms_update(
    headers: AuthorizationHeader,
    rooms: List[Room],
) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    await Room.update_many(rooms)
