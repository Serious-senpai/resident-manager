from __future__ import annotations

from datetime import datetime
from typing import Optional, TYPE_CHECKING


__all__ = ("PersonalInfo",)


class PersonalInfo:
    """Base class for objects holding personal information."""

    __slots__ = (
        "name",
        "room",
        "birthday",
        "phone",
        "email",
        "username",
        "hashed_password",
    )
    if TYPE_CHECKING:
        name: str
        room: int
        birthday: Optional[datetime]
        phone: Optional[str]
        email: Optional[str]
        username: str
        hashed_password: str

    def __init__(
        self,
        *,
        name: str,
        room: int,
        birthday: Optional[datetime],
        phone: Optional[str],
        email: Optional[str],
        username: str,
        hashed_password: str,
    ) -> None:
        self.name = name
        self.room = room
        self.birthday = birthday
        self.phone = phone
        self.email = email
        self.username = username
        self.hashed_password = hashed_password
