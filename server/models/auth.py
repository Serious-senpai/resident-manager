from __future__ import annotations

from typing import Annotated, Optional, cast

import pydantic
from fastapi import Header
from nacl.encoding import Base64Encoder
from nacl.public import Box, PublicKey

from .results import Result
from ..database import Database
from ..security import SERVER_SECRET_KEY
from ..utils import check_password


__all__ = ("Authorization", "AuthorizationHeader", "HashedAuthorization")


class Authorization(pydantic.BaseModel):
    """Data model for authorization headers"""

    username: str
    encrypted: str
    pkey: str

    def decrypt_password(self) -> Result[Optional[str]]:
        try:
            box = Box(SERVER_SECRET_KEY, PublicKey(self.pkey.encode("utf-8"), encoder=Base64Encoder))
            password = box.decrypt(self.encrypted.encode("utf-8"), encoder=Base64Encoder).decode("utf-8")
            return Result(data=password)

        except BaseException:
            return Result(code=204, data=None)

    @staticmethod
    async def verify_admin(username: str, password: str) -> Optional[Result[None]]:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("SELECT * FROM config WHERE name = 'admin_username' OR name = 'admin_hashed_password'")
                rows = await cursor.fetchall()

                if len(rows) != 2:
                    raise RuntimeError("Invalid database format. Couldn't verify admin login.")

                for name, value in rows:
                    if name == "admin_username":
                        if username != value:
                            return Result(code=203, data=None)

                    else:
                        if not check_password(password, hashed=value):
                            return Result(code=203, data=None)

        return None

    @staticmethod
    async def verify_admin_headers(headers: Authorization) -> Optional[Result[None]]:
        password = headers.decrypt_password()
        if password.data is None:
            return cast(Result[None], password)

        return await Authorization.verify_admin(headers.username, password.data)


AuthorizationHeader = Annotated[Authorization, Header(description="Authorization headers")]


class HashedAuthorization(pydantic.BaseModel):
    """Data model for authorization with hashed password.

    Keep in mind that using underscore in headers is not safe.
    """

    username: str
    hashed_password: str
