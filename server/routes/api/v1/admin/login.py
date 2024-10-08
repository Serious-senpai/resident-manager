from __future__ import annotations

from fastapi import status

from .....apps import api_v1
from .....errors import AuthenticationRequired, PasswordDecryptionError, register_error
from .....database import Database
from .....models import AuthorizationHeader


__all__ = ("admin_login",)


@api_v1.post(
    "/admin/login",
    name="Administrators login",
    description="Verify administrator authorization data.",
    tags=["admin"],
    response_model=None,
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_login(headers: AuthorizationHeader) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
