from __future__ import annotations

import asyncio
import traceback
import sys
from datetime import datetime, timedelta, timezone
from typing import Annotated, ClassVar, Final, Literal, Optional

import jwt
import pydantic
from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer

from ...database import Database
from ...utils import check_password


__all__ = (
    "secret_key",
    "HashedAuthorization",
    "Token",
    "AdminPermission",
)
ALGORITHM: Final[Literal["HS256"]] = "HS256"
TOKEN_EXPIRE_MINUTES: Final[int] = 30


class __SecretKeyQuery:
    running: ClassVar[Optional[asyncio.Task[str]]] = None

    @staticmethod
    async def __query() -> str:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("SELECT value FROM config WHERE name = 'session_secret_key'")
                return await cursor.fetchval()

    @classmethod
    def __reload(cls) -> None:
        cls.running = None

    @classmethod
    async def query(cls) -> str:
        if cls.running is None:
            cls.running = task = asyncio.create_task(cls.__query())
            task.add_done_callback(lambda _: cls.__reload())

        return await cls.running


secret_key = __SecretKeyQuery.query


class HashedAuthorization(pydantic.BaseModel):
    """Data model for authorization with hashed password.

    Keep in mind that using underscore in headers is not safe.
    """

    username: Annotated[str, pydantic.Field(description="The username for authorization")]
    hashed_password: Annotated[str, pydantic.Field(description="The SHA256-hashed password stored in the database")]


class Token(pydantic.BaseModel):
    """Data model for a token response."""

    access_token: str
    token_type: Literal["bearer"]

    oauth2_resident: ClassVar[OAuth2PasswordBearer] = OAuth2PasswordBearer("login", scheme_name="oauth2_resident")
    oauth2_admin: ClassVar[OAuth2PasswordBearer] = OAuth2PasswordBearer("admin/login", scheme_name="oauth2_admin")

    @classmethod
    def create(cls, object: pydantic.BaseModel, *, secret_key: str) -> Token:
        to_encode = object.model_dump()
        expire = datetime.now(timezone.utc) + timedelta(minutes=TOKEN_EXPIRE_MINUTES)

        to_encode.update({"exp": expire})
        return cls(
            access_token=jwt.encode(to_encode, secret_key, ALGORITHM),
            token_type="bearer",
        )


class AdminPermission(pydantic.BaseModel):
    """Data model for admin permissions."""

    admin: bool

    @staticmethod
    def create_token(*, secret_key: str) -> Token:
        return Token.create(AdminPermission(admin=True), secret_key=secret_key)

    @staticmethod
    async def verify(*, username: str, password: str) -> bool:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("EXECUTE QueryAdminInfo")

                row = await cursor.fetchone()
                return username == row[0] and check_password(password, hashed=row[1])

    @classmethod
    async def from_token(cls, token: Annotated[str, Depends(Token.oauth2_admin)]) -> AdminPermission:
        try:
            payload = jwt.decode(token, await secret_key(), algorithms=[ALGORITHM], options={"require": ["exp"]})
            return cls(admin=payload["admin"])

        except Exception:
            print("Unauthorized administrator access:", file=sys.stderr)
            traceback.print_exc(file=sys.stderr)
            return cls(admin=False)
