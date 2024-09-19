from __future__ import annotations

import asyncio
from datetime import datetime
from typing import Any, ClassVar, Dict, Optional, TypeVar

from .info import HashedAccountInfo
from ..database import Database
from ..utils import snowflake_time


__all__ = ("Resident",)
T = TypeVar("T")


class Resident(HashedAccountInfo):
    """Data model for objects holding information about a resident."""

    id: int

    @property
    def created_at(self) -> datetime:
        return snowflake_time(self.id)

    __cache_by_id: ClassVar[Dict[int, Resident]] = {}
    __cache_by_username: ClassVar[Dict[str, Resident]] = {}
    __fetch_lock: ClassVar[asyncio.Lock] = asyncio.Lock()

    @classmethod
    def from_row(cls, row: Any) -> Resident:
        return cls(
            id=row[0],
            name=row[1],
            room=row[2],
            birthday=row[3],
            phone=row[4],
            email=row[5],
            username=row[6],
            hashed_password=row[7],
        )

    @classmethod
    async def __fetch(cls, *, key: T, cache: Dict[T, Resident], db_column: str) -> Optional[Resident]:
        async with cls.__fetch_lock:
            try:
                return cache[key]

            except KeyError:
                async with Database.instance.pool.acquire() as connection:
                    async with connection.cursor() as cursor:
                        await cursor.execute("SELECT * FROM residents WHERE ? = ?", db_column, key)
                        rows = await cursor.fetchall()

                        if len(rows) == 0:
                            return None

                        row = rows[0]
                        resident = cls.from_row(row)
                        cls.__cache_by_id[resident.id] = cls.__cache_by_username[resident.username] = resident

                        return resident

    @classmethod
    async def from_id(cls, id: int) -> Optional[Resident]:
        """This function is a coroutine.

        Fetch a resident from the cache with a specified ID. If the resident is not in the cache, fetch and cache
        from the database instead.

        Parameters
        -----
        id: `int`
            The ID of the resident to fetch.

        Returns
        -----
        `Optional[Resident]`
            The resident with the specified ID, or `None` if not found.
        """
        return await cls.__fetch(key=id, cache=cls.__cache_by_id, db_column="resident_id")

    @classmethod
    async def from_username(cls, username: str) -> Optional[Resident]:
        """This function is a coroutine.

        Fetch a resident from the cache with a specified username. If the resident is not in the cache, fetch and cache
        from the database instead.

        Parameters
        -----
        username: `str`
            The username of the resident to fetch.

        Returns
        -----
        `Optional[Resident]`
            The resident with the specified username, or `None` if not found.
        """
        return await cls.__fetch(key=username, cache=cls.__cache_by_username, db_column="username")
