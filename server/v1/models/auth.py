from __future__ import annotations

import asyncio
from typing import Annotated, ClassVar, Optional, cast

import pydantic
from fastapi import Header

from .results import Result
from ..database import Database
from ..utils import check_password


__all__ = ("Authorization", "AuthorizationHeader", "HashedAuthorization")


class Authorization(pydantic.BaseModel):
    """Data model for authorization headers"""

    username: Annotated[str, pydantic.Field(description="The username for authorization")]
    password: Annotated[str, pydantic.Field(description="The password for authorization")]

    admin_username: ClassVar[Optional[str]] = None
    admin_hashed_password: ClassVar[Optional[str]] = None
    admin_lock: ClassVar[asyncio.Lock] = asyncio.Lock()

    async def verify_admin(self) -> Optional[Result[None]]:
        async with Authorization.admin_lock:
            if Authorization.admin_username is None or Authorization.admin_hashed_password is None:
                async with Database.instance.pool.acquire() as connection:
                    async with connection.cursor() as cursor:
                        await cursor.execute("SELECT * FROM config WHERE name = 'admin_username'")
                        row = await cursor.fetchone()
                        Authorization.admin_username = cast(str, row[1])

                        await cursor.execute("SELECT * FROM config WHERE name = 'admin_hashed_password'")
                        row = await cursor.fetchone()
                        Authorization.admin_hashed_password = cast(str, row[1])

        if self.username == Authorization.admin_username and check_password(self.password, hashed=Authorization.admin_hashed_password):
            return None

        return Result(code=203, data=None)


AuthorizationHeader = Annotated[Authorization, Header(description="Authorization headers")]


class HashedAuthorization(pydantic.BaseModel):
    """Data model for authorization with hashed password.

    Keep in mind that using underscore in headers is not safe.
    """

    username: Annotated[str, pydantic.Field(description="The username for authorization")]
    hashed_password: Annotated[str, pydantic.Field(description="The SHA256-hashed password stored in the database")]
