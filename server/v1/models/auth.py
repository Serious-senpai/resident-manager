from __future__ import annotations

from typing import Annotated, Optional

import pydantic
from fastapi import Header

from .results import Result
from ..database import Database
from ..utils import check_password


__all__ = ("Authorization", "AuthorizationHeader", "HashedAuthorization")


class Authorization(pydantic.BaseModel):
    """Data model for authorization headers"""

    username: str
    password: str

    async def verify_admin(self) -> Optional[Result[None]]:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("SELECT * FROM config WHERE name = 'admin_username' OR name = 'admin_hashed_password'")
                rows = await cursor.fetchall()

                if len(rows) != 2:
                    raise RuntimeError("Invalid database format. Couldn't verify admin login.")

                for name, value in rows:
                    if name == "admin_username":
                        if self.username != value:
                            return Result(code=203, data=None)

                    else:
                        if not check_password(self.password, hashed=value):
                            return Result(code=203, data=None)

        return None


AuthorizationHeader = Annotated[Authorization, Header(description="Authorization headers")]


class HashedAuthorization(pydantic.BaseModel):
    """Data model for authorization with hashed password.

    Keep in mind that using underscore in headers is not safe.
    """

    username: str
    hashed_password: str
