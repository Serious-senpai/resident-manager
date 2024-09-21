from __future__ import annotations

from datetime import datetime
from typing import Optional

import pydantic

from .snowflake import Snowflake


__all__ = ("PersonalInfo", "PublicInfo")


class PersonalInfo(pydantic.BaseModel):
    """Data model for objects holding personal information."""

    name: str
    room: int
    birthday: Optional[datetime]
    phone: Optional[str]
    email: Optional[str]

    def to_personal_info(self) -> PersonalInfo:
        return PersonalInfo(
            name=self.name,
            room=self.room,
            birthday=self.birthday,
            phone=self.phone,
            email=self.email,
        )


class PublicInfo(Snowflake, PersonalInfo):
    """Data model for objects holding personal info along with a snowflake ID."""

    def to_public_info(self) -> PublicInfo:
        return PublicInfo(
            id=self.id,
            name=self.name,
            room=self.room,
            birthday=self.birthday,
            phone=self.phone,
            email=self.email,
        )
