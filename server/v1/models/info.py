from __future__ import annotations

from datetime import date
from typing import Annotated, Optional

import pydantic

from .results import Result
from .snowflake import Snowflake
from ...utils import (
    validate_name,
    validate_room,
    validate_phone,
    validate_email,
)


__all__ = ("PersonalInfo", "PublicInfo")


class PersonalInfo(pydantic.BaseModel):
    """Data model for objects holding personal information."""

    name: Annotated[str, pydantic.Field(description="The full name of the resident")]
    room: Annotated[int, pydantic.Field(description="The room number of the resident")]
    birthday: Annotated[Optional[date], pydantic.Field(description="The resident's date of birth")] = None
    phone: Annotated[str, pydantic.Field(description="The resident's phone number")]
    email: Annotated[Optional[str], pydantic.Field(description="The resident's email")] = None

    def to_personal_info(self) -> PersonalInfo:
        return PersonalInfo(
            name=self.name,
            room=self.room,
            birthday=self.birthday,
            phone=self.phone,
            email=self.email,
        )

    def validate_info(self) -> Optional[Result[None]]:
        if self.email is None or len(self.email) == 0:
            self.email = None

        if not validate_name(self.name):
            return Result(code=101, data=None)

        if not validate_room(self.room):
            return Result(code=102, data=None)

        if not validate_phone(self.phone):
            return Result(code=103, data=None)

        if self.email is not None and not validate_email(self.email):
            return Result(code=104, data=None)

        return None


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
