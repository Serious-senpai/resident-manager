from __future__ import annotations

from datetime import datetime
from typing import Optional

import pydantic

from .auth import Authorization, HashedAuthorization


__all__ = ("PersonalInfo", "AccountInfo", "HashedAccountInfo")


class PersonalInfo(pydantic.BaseModel):
    """Data model for objects holding personal information."""

    name: str
    room: int
    birthday: Optional[datetime]
    phone: Optional[str]
    email: Optional[str]


class AccountInfo(PersonalInfo, Authorization):
    """Data model for objects holding resident account information"""
    pass


class HashedAccountInfo(PersonalInfo, HashedAuthorization):
    """Data model for objects holding resident account information with hashed password."""
    pass
