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
    response_model=None,
    responses={status.HTTP_403_FORBIDDEN: {}},
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_login(headers: Annotated[Authorization, Header()]) -> None:
    """Verify administrator authorization data, return 204 on success, 403 on failure"""
    if await Database.instance.verify_admin(headers.username, headers.password):
        return None

    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
