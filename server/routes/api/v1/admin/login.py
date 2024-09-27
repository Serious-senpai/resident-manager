from __future__ import annotations

from typing import Annotated

from fastapi import HTTPException, Header, status

from .....apps import api_v1
from .....database import Database
from .....models import Authorization


__success_status = status.HTTP_204_NO_CONTENT
__failure_status = status.HTTP_403_FORBIDDEN


@api_v1.post(
    "/admin/login",
    name="Administrators login",
    description=f"Verify administrator authorization data, return {__success_status} on success, {__failure_status} on failure",
    tags=["admin"],
    response_model=None,
    responses={__failure_status: {}},
    status_code=__success_status,
)
async def admin_login(headers: Annotated[Authorization, Header()]) -> None:
    if await Database.instance.verify_admin(headers.username, headers.password):
        return None

    raise HTTPException(status_code=__failure_status)
