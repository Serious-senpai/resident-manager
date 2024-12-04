from __future__ import annotations

from typing import Any, List, Optional, Tuple, TypeVar

from pyodbc import Row  # type: ignore
from typing_extensions import Self

from .auth import HashedAuthorization
from .info import PublicInfo
from ...utils import (
    validate_name,
    validate_room,
    validate_username,
)


__all__ = ("Account",)
T = TypeVar("T")


class Account(PublicInfo, HashedAuthorization):
    @classmethod
    def from_row(cls, row: Row) -> Self:
        return cls(
            id=row.id,
            name=row.name,
            room=row.room,
            birthday=row.birthday,
            phone=row.phone,
            email=row.email,
            username=row.username,
            hashed_password=row.hashed_password,
        )

    @staticmethod
    def build_sql_condition(
        *,
        id: Optional[int] = None,
        name: Optional[str] = None,
        room: Optional[int] = None,
        username: Optional[str] = None,
    ) -> Optional[Tuple[List[str], List[Any]]]:
        where: List[str] = []
        params: List[Any] = []

        if id is not None:
            where.append("id = ?")
            params.append(id)

        if name is not None:
            if not validate_name(name):
                return None

            where.append("CHARINDEX(?, name) > 0")
            params.append(name)

        if room is not None:
            if not validate_room(room):
                return None

            where.append("room = ?")
            params.append(room)

        if username is not None:
            if not validate_username(username):
                return None

            where.append("CHARINDEX(?, username) > 0")
            params.append(username)

        return where, params
