from __future__ import annotations

import pydantic


__all__ = ("Authorization", "HashedAuthorization")


class Authorization(pydantic.BaseModel):
    """Data model for authorization headers"""

    username: str
    password: str


class HashedAuthorization(pydantic.BaseModel):
    """Data model for authorization headers with hashed password."""

    username: str
    hashed_password: str
