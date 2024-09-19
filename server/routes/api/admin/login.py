from __future__ import annotations

from typing import Annotated

import fastapi
from fastapi import status

from ....database import Database
from ....models import Authorization
from ....routers import api_router


# Not much we can do: https://stackoverflow.com/a/7562744
@api_router.post(
    "/admin/login",
    name="Administrators login",
    tags=["authorization", "admin"],
    responses={status.HTTP_403_FORBIDDEN: {}},
)
async def admin_login(headers: Annotated[Authorization, fastapi.Header()]) -> None:
    """Verify administrator authorization data, return 200 on success, 403 on failure"""
    if await Database.instance.verify_admin(headers.username, headers.password):
        return

    raise fastapi.HTTPException(status_code=status.HTTP_403_FORBIDDEN)
