from __future__ import annotations

from typing import Any, List, Literal, Optional, TypeVar

from .auth import AuthorizationHeader, HashedAuthorization
from .info import PublicInfo
from .results import Result
from .snowflake import Snowflake
from ..config import DB_PAGINATION_QUERY
from ..database import Database
from ..utils import (
    check_password,
    validate_name,
    validate_room,
    validate_username,
)


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
        order_by: Literal["resident_id", "name", "room", "username"] = "resident_id",
        ascending: bool = True,
    ) -> List[Resident]:
        where: List[str] = []
        params: List[Any] = []

        if id is not None:
            where.append("resident_id = ?")
            params.append(id)

        if name is not None:
            if len(name) == 0 or len(name) > 255:
                return []

            where.append("CHARINDEX(?, name) > 0")
            params.append(name)

        if room is not None:
            if not validate_room(room):
                return []

            where.append("room = ?")
            params.append(room)

        if username is not None:
            if not validate_username(username):
                return []

            where.append("username = ?")
            params.append(username)

        query = ["SELECT * FROM residents"]
        if len(where) > 0:
            query.append("WHERE " + " AND ".join(where))

        if order_by not in {"resident_id", "name", "room", "username"}:
            order_by = "resident_id"

        asc_desc = "ASC" if ascending else "DESC"
        query.append(f"ORDER BY {order_by} {asc_desc} OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]

    @classmethod
    async def delete_many(cls, objects: List[Snowflake]) -> None:
        if len(objects) == 0:
            return

        async with Database.instance.pool.acquire() as connection:
            temp_fmt = ", ".join("?" for _ in objects)
            async with connection.cursor() as cursor:
                await cursor.execute(f"DELETE FROM residents WHERE resident_id IN ({temp_fmt})", *[o.id for o in objects])

    @staticmethod
    async def count(
        *,
        id: Optional[int] = None,
        name: Optional[str] = None,
        room: Optional[int] = None,
        username: Optional[str] = None,
    ) -> int:
        where: List[str] = []
        params: List[Any] = []

        if id is not None:
            where.append("resident_id = ?")
            params.append(id)

        if name is not None:
            if not validate_name(name):
                return 0

            where.append("CHARINDEX(?, name) > 0")
            params.append(name)

        if room is not None:
            if not validate_room(room):
                return 0

            where.append("room = ?")
            params.append(room)

        if username is not None:
            if not validate_username(username):
                return 0

            where.append("username = ?")
            params.append(username)

        query = ["SELECT COUNT(resident_id) FROM residents"]
        if len(where) > 0:
            query.append("WHERE " + " AND ".join(where))

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("\n".join(query), *params)
                return await cursor.fetchval()

    @classmethod
    async def authorize(cls, headers: AuthorizationHeader) -> Result[Optional[Resident]]:
        residents = await cls.query(username=headers.username)
        if len(residents) == 0:
            return Result(code=201, data=None)

        resident = residents[0]
        if not check_password(headers.password, hashed=resident.hashed_password):
            return Result(code=202, data=None)

        return Result(data=resident)

    @classmethod
    async def update(cls, *, id: int, info: PublicInfo) -> Result[Optional[Resident]]:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                        UPDATE residents
                        SET
                            name = ?,
                            room = ?,
                            birthday = ?,
                            phone = ?,
                            email = ?
                        OUTPUT INSERTED.*
                        WHERE resident_id = ?
                    """,
                    info.name,
                    info.room,
                    info.birthday,
                    info.phone,
                    info.email,
                    id,
                )

                row = await cursor.fetchone()
                if row is not None:
                    return Result(data=cls.from_row(row))

        return Result(code=302, data=None)
