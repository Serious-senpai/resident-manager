from __future__ import annotations

from datetime import datetime
from typing import Annotated, Optional

import pydantic

from .snowflake import Snowflake


__all__ = ("PersonalInfo", "PublicInfo")


class PersonalInfo(pydantic.BaseModel):
    """Data model for objects holding personal information."""

    name: Annotated[str, pydantic.Field(description="The full name of the resident")]
    room: Annotated[int, pydantic.Field(description="The room number of the resident")]
    birthday: Annotated[Optional[datetime], pydantic.Field(description="The resident's date of birth")] = None
    phone: Annotated[Optional[str], pydantic.Field(description="The resident's phone number")] = None
    email: Annotated[Optional[str], pydantic.Field(description="The resident's email")] = None

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
