from __future__ import annotations

from typing import Annotated

from fastapi import HTTPException, Header, status

from ....database import Database
from ....models import Authorization
from ....routers import api_router


@api_router.post(
    "/admin/login",
    name="Administrators login",
    tags=["authorization", "admin"],
    responses={status.HTTP_403_FORBIDDEN: {}},
    status_code=status.HTTP_200_OK,
)
async def admin_login(headers: Annotated[Authorization, Header()]) -> None:
    """Verify administrator authorization data, return 200 on success, 403 on failure"""
    if await Database.instance.verify_admin(headers.username, headers.password):
        return

    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
