from __future__ import annotations

from typing import Annotated

from fastapi import Header, status

from .....apps import api_v1
from .....database import Database
from .....models import Authorization


@api_v1.post(
    "/admin/login",
    name="Administrators login",
    description="Verify administrator authorization data.",
    tags=["admin"],
    response_model=None,
    responses={status.HTTP_403_FORBIDDEN: {}},
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_login(headers: Annotated[Authorization, Header()]) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
