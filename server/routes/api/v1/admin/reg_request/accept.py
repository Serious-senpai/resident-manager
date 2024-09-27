from __future__ import annotations

from typing import Annotated, List

from fastapi import Header, status

from ......apps import api_v1
from ......database import Database
from ......models import Authorization, RegisterRequest


@api_v1.post(
    "/admin/reg-request/accept",
    name="Registration requests approval",
    description="Approve one or more registration requests",
    tags=["admin"],
    response_model=None,
    responses={status.HTTP_401_UNAUTHORIZED: {}, status.HTTP_403_FORBIDDEN: {}},
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_reg_request_accept(ids: List[int], headers: Annotated[Authorization, Header()]) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    await RegisterRequest.accept_many(ids)
