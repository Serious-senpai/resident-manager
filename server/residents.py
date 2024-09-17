from __future__ import annotations

import asyncio
from datetime import datetime
from typing import ClassVar, Dict, Optional, TypeVar, TYPE_CHECKING

from .database import Database
from .snowflake import Snowflake


__all__ = ("Resident",)
T = TypeVar("T")


class Resident(Snowflake):

    __slots__ = (
        "name",
        "room",
        "birthday",
        "phone",
        "email",
        "username",
        "hashed_password",
    )
    __cache_by_id: ClassVar[Dict[int, Resident]] = {}
    __cache_by_username: ClassVar[Dict[str, Resident]] = {}
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
        id: int,
        name: str,
        room: int,
        birthday: Optional[datetime],
        phone: Optional[str],
        email: Optional[str],
        username: str,
        hashed_password: str,
    ) -> None:
        super().__init__(id=id)

        self.name = name
        self.room = room
        self.birthday = birthday
        self.phone = phone
        self.email = email
        self.username = username
        self.hashed_password = hashed_password

    @classmethod
    async def __fetch(cls, *, key: T, cache: Dict[T, Resident], db_column: str) -> Optional[Resident]:
        try:
            return cache[key]

        except KeyError:
            database = Database()
            await database.prepare()

            async with database.pool.acquire() as connection:
                async with connection.cursor() as cursor:
                    await cursor.execute("SELECT * FROM residents WHERE ? = ?", db_column, key)
                    rows = await cursor.fetchall()

                    if len(rows) == 0:
                        return None

                    row = rows[0]
                    resident = cls(
                        id=row[0],
                        name=row[1],
                        room=row[2],
                        birthday=row[3],
                        phone=row[4],
                        email=row[5],
                        username=row[6],
                        hashed_password=row[7],
                    )

                    return resident

    __from_id_lock: ClassVar[asyncio.Lock] = asyncio.Lock()

    @classmethod
    async def from_id(cls, id: int) -> Optional[Resident]:
        async with cls.__from_id_lock:
            resident = await cls.__fetch(key=id, cache=cls.__cache_by_id, db_column="resident_id")
            if resident is not None:
                cls.__cache_by_id[id] = resident

        return resident

    __from_username_lock: ClassVar[asyncio.Lock] = asyncio.Lock()

    @classmethod
    async def from_username(cls, username: str) -> Optional[Resident]:
        async with cls.__from_username_lock:
            resident = await cls.__fetch(key=username, cache=cls.__cache_by_username, db_column="username")
            if resident is not None:
                cls.__cache_by_username[username] = resident

        return resident
