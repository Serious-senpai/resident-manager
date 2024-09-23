from __future__ import annotations

from typing import Annotated

from fastapi import HTTPException, Header, status

from .....database import Database
from .....models import Authorization, RegisterRequest
from .....routers import api_router


@api_router.get(
    "/admin/reg-request/count",
    name="Registration requests count",
    description="Return number of registration requests",
    tags=["admin"],
    responses={status.HTTP_401_UNAUTHORIZED: {}},
    status_code=status.HTTP_200_OK,
)
async def admin_reg_request_count(headers: Annotated[Authorization, Header()]) -> int:
    if not await Database.instance.verify_admin(headers.username, headers.password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    return await RegisterRequest.count()
