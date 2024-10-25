from __future__ import annotations

import secrets
from datetime import datetime, timedelta, timezone
from typing import Annotated, ClassVar, Literal

import jwt
import pydantic
from fastapi import Depends
from fastapi.security import OAuth2PasswordBearer


__all__ = (
    "HashedAuthorization",
    "Token",
    "AdminPermission",
)


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

    SECRET_KEY: ClassVar[str] = secrets.token_hex(32)
    ALGORITHM: ClassVar[Literal["HS256"]] = "HS256"
    TOKEN_EXPIRE_MINUTES: ClassVar[int] = 30

    oauth2_resident: ClassVar[OAuth2PasswordBearer] = OAuth2PasswordBearer("login", scheme_name="oauth2_resident")
    oauth2_admin: ClassVar[OAuth2PasswordBearer] = OAuth2PasswordBearer("admin/login", scheme_name="oauth2_admin")

    @classmethod
    def create(cls, object: pydantic.BaseModel) -> Token:
        to_encode = object.model_dump()
        expire = datetime.now(timezone.utc) + timedelta(minutes=cls.TOKEN_EXPIRE_MINUTES)

        to_encode.update({"exp": expire})
        return cls(
            access_token=jwt.encode(to_encode, cls.SECRET_KEY, cls.ALGORITHM),
            token_type="bearer",
        )


class AdminPermission(pydantic.BaseModel):
    """Data model for admin permissions."""

    admin: bool

    @staticmethod
    def create_token() -> Token:
        return Token.create(AdminPermission(admin=True))

    @classmethod
    def from_token(cls, token: Annotated[str, Depends(Token.oauth2_admin)]) -> AdminPermission:
        try:
            payload = jwt.decode(token, Token.SECRET_KEY, algorithms=[Token.ALGORITHM])
            return cls(admin=payload.get("admin", False))

        except jwt.PyJWTError:
            return cls(admin=False)
