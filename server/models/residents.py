from __future__ import annotations

from typing import Any, List, Optional, TypeVar

from .auth import HashedAuthorization
from .info import PublicInfo
from ..config import DB_PAGINATION_QUERY
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
    async def query(
        cls,
        *,
        offset: int = 0,
        id: Optional[int] = None,
        name: Optional[str] = None,
        room: Optional[int] = None,
        username: Optional[str] = None,
    ) -> List[Resident]:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                where: List[str] = []
                params: List[Any] = []

                if id is not None:
                    where.append("resident_id = ?")
                    params.append(id)

                if name is not None and len(name) > 0:
                    where.append("CHARINDEX(?, name) > 0")
                    params.append(name)

                if room is not None:
                    where.append("room = ?")
                    params.append(room)

                if username is not None and len(username) > 0:
                    where.append("username = ?")
                    params.append(username)

                query = ["SELECT * FROM residents"]
                if len(where) > 0:
                    query.append("WHERE " + " AND ".join(where))

                query.append("ORDER BY resident_id DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]

    @classmethod
    async def delete_many(cls, ids: List[int]) -> None:
        if len(ids) == 0:
            return

        async with Database.instance.pool.acquire() as connection:
            temp_fmt = ", ".join("?" for _ in ids)
            async with connection.cursor() as cursor:
                await cursor.execute(f"DELETE FROM residents WHERE resident_id IN ({temp_fmt})", *ids)
