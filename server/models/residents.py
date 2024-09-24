from __future__ import annotations

from typing import Any, Optional, TypeVar

from .auth import HashedAuthorization
from .info import PublicInfo
from ..database import Database


__all__ = ("Resident",)
T = TypeVar("T")


class Resident(PublicInfo, HashedAuthorization):
    """Data model for objects holding information about a resident.

    Each object of this class corresponds to a database row."""

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
    async def from_id(cls, id: int) -> Optional[Resident]:
        """This function is a coroutine.

        Fetch a resident from the database with a specified ID.

        Parameters
        -----
        id: `int`
            The ID of the resident to fetch.

        Returns
        -----
        `Optional[Resident]`
            The resident with the specified ID, or `None` if not found.
        """
        async with Database.instance.pool.acquire() as connection:
            cursor = await connection.execute("SELECT * FROM residents WHERE id = ?", id)
            row = await cursor.fetchone()

            if row is None:
                return None

            return cls.from_row(row)

    @classmethod
    async def from_username(cls, username: str) -> Optional[Resident]:
        """This function is a coroutine.

        Fetch a resident from the database with a specified username.

        Parameters
        -----
        username: `str`
            The username of the resident to fetch.

        Returns
        -----
        `Optional[Resident]`
            The resident with the specified username, or `None` if not found.
        """
        async with Database.instance.pool.acquire() as connection:
            cursor = await connection.execute("SELECT * FROM residents WHERE username = ?", username)
            row = await cursor.fetchone()

            if row is None:
                return None

            return cls.from_row(row)
