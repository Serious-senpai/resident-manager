from __future__ import annotations

from typing import Annotated, List

from fastapi import Header, status

from .....apps import api_v1
from .....database import Database
from .....errors import AuthenticationRequired, PasswordDecryptionError, register_error
from .....models import Authorization, Resident


@api_v1.post(
    "/admin/delete",
    name="Account deletion",
    description="Delete one or more resident accounts",
    tags=["admin"],
    response_model=None,
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_delete(ids: List[int], headers: Annotated[Authorization, Header()]) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    await Resident.delete_many(ids)
