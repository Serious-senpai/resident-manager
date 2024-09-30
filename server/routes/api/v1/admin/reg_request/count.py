from __future__ import annotations

from typing import Annotated

from fastapi import Header, status

from ......apps import api_v1
from ......database import Database
from ......errors import AuthenticationRequired, PasswordDecryptionError, register_error
from ......models import Authorization, RegisterRequest


__all__ = ("admin_reg_request_count",)


@api_v1.get(
    "/admin/reg-request/count",
    name="Registration requests count",
    description="Return number of registration requests",
    tags=["admin"],
    responses=register_error(AuthenticationRequired, PasswordDecryptionError),
    status_code=status.HTTP_200_OK,
)
async def admin_reg_request_count(headers: Annotated[Authorization, Header()]) -> int:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    return await RegisterRequest.count()
