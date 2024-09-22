from __future__ import annotations

from typing import Annotated

from fastapi import HTTPException, Header, status

from ....database import Database
from ....models import Authorization
from ....routers import api_router


__success_status = status.HTTP_204_NO_CONTENT
__failure_status = status.HTTP_403_FORBIDDEN


@api_router.post(
    "/admin/login",
    name="Administrators login",
    description=f"Verify administrator authorization data, return {__success_status} on success, {__failure_status} on failure",
    tags=["authorization", "admin"],
    response_model=None,
    responses={__failure_status: {}},
    status_code=__success_status,
)
async def admin_login(headers: Annotated[Authorization, Header()]) -> None:
    if await Database.instance.verify_admin(headers.username, headers.password):
        return None

    raise HTTPException(status_code=__failure_status)
