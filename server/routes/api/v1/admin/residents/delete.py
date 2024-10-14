from __future__ import annotations

from typing import List

from fastapi import status

from ......apps import api_v1
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import AuthorizationHeader, Resident, Snowflake


__all__ = ("admin_residents_delete",)


@api_v1.post(
    "/admin/residents/delete",
    name="Account deletion",
    description="Delete one or more resident accounts",
    tags=["admin"],
    response_model=None,
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_residents_delete(headers: AuthorizationHeader, objects: List[Snowflake]) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    await Resident.delete_many(objects)
