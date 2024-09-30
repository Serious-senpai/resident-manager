from __future__ import annotations

from typing import List

from fastapi import status

from ......apps import api_v1
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import AuthorizationHeader, RegisterRequest, Snowflake


__all__ = ("admin_reg_request_accept",)


@api_v1.post(
    "/admin/reg-request/accept",
    name="Registration requests approval",
    description="Approve one or more registration requests",
    tags=["admin"],
    response_model=None,
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_reg_request_accept(headers: AuthorizationHeader, objects: List[Snowflake]) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    await RegisterRequest.accept_many(objects)
