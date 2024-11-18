from __future__ import annotations

import asyncio
from typing import Annotated, ClassVar, Optional, cast

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from ...app import api_v1
from ...models import AdminPermission, Token
from ....database import Database
from ....utils import check_password


__all__ = ("login",)


class _AdminAuth:
    admin_lock: ClassVar[asyncio.Lock] = asyncio.Lock()
    admin_username: ClassVar[Optional[str]] = None
    admin_hashed_password: ClassVar[Optional[str]] = None


@api_v1.post(
    "/admin/login",
    name="Administrators login",
    description="Verify administrator authorization data.",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "Successfully logged in",
            "model": Token,
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
        },
    },
)
async def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]) -> Token:
    async with _AdminAuth.admin_lock:
        if _AdminAuth.admin_username is None or _AdminAuth.admin_hashed_password is None:
            async with Database.instance.pool.acquire() as connection:
                async with connection.cursor() as cursor:
                    await cursor.execute("SELECT value FROM config WHERE name = 'admin_username'")
                    _AdminAuth.admin_username = cast(str, await cursor.fetchval())

                    await cursor.execute("SELECT value FROM config WHERE name = 'admin_hashed_password'")
                    _AdminAuth.admin_hashed_password = cast(str, await cursor.fetchval())

    if form_data.username == _AdminAuth.admin_username and check_password(form_data.password, hashed=_AdminAuth.admin_hashed_password):
        return AdminPermission.create_token()

    raise HTTPException(status.HTTP_400_BAD_REQUEST)
