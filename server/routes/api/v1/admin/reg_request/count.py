from __future__ import annotations

from typing import Annotated

from fastapi import Header, status

from ......apps import api_v1
from ......database import Database
from ......models import Authorization, RegisterRequest


@api_v1.get(
    "/admin/reg-request/count",
    name="Registration requests count",
    description="Return number of registration requests",
    tags=["admin"],
    responses={status.HTTP_401_UNAUTHORIZED: {}, status.HTTP_403_FORBIDDEN: {}},
    status_code=status.HTTP_200_OK,
)
async def admin_reg_request_count(headers: Annotated[Authorization, Header()]) -> int:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    return await RegisterRequest.count()
