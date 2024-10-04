from __future__ import annotations

from typing import Any, List, Optional

import pydantic

from ..config import DB_PAGINATION_QUERY
from ..database import Database


__all__ = ("Room",)


class Room(pydantic.BaseModel):
    """Data model for objects holding room information.

    Each object of this class corresponds to a database row.
    """

    room: int
    area: float
    motorbike: int
    car: int

    @classmethod
    def from_row(cls, row: Any) -> Room:
        return cls(
            room=row[0],
            area=row[1] / 100,
            motorbike=row[2],
            car=row[3],
        )

    @staticmethod
    async def count(
        *,
        room: Optional[int] = None,
        floor: Optional[int] = None,
    ) -> int:
        where: List[str] = []
        params: List[Any] = []

        if room is not None:
            where.append("room = ?")
            params.append(room)

        if floor is not None:
            where.append("room / 100 = ?")
            params.append(floor)

        query = ["SELECT COUNT(*) FROM rooms"]
        if len(where) > 0:
            query.append("WHERE " + " AND ".join(where))

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("\n".join(query), *params)
                return await cursor.fetchval()

    @classmethod
    async def query(
        cls,
        offset: int,
        room: Optional[int] = None,
        floor: Optional[int] = None,
    ) -> List[Room]:
        """This function is a coroutine.

        Query room information from the database.

        Parameters
        -----
        offset: `int`
            The offset from which to query the room information.
        room: `Optional[int]`
            The room number to filter the query.
        floor: `Optional[int]`
            The floor number to filter the query.

        Returns
        -----
        `List[Room]`
            A list of room information objects.
        """
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                where: List[str] = []
                params: List[Any] = []

                if room is not None:
                    where.append("room = ?")
                    params.append(room)

                if floor is not None:
                    where.append("room / 100 = ?")
                    params.append(floor)

                query = ["SELECT * FROM rooms"]
                if len(where) > 0:
                    query.append("WHERE " + " AND ".join(where))

                query.append("ORDER BY room DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]

    @staticmethod
    async def update_many(rooms: List[Room]) -> None:
        """This function is a coroutine.

        Update room information in the database.

        Parameters
        -----
        rooms: `List[Room]`
            A list of room information objects to update.
        """
        if len(rooms) == 0:
            return

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                params = [
                    (
                        room.room,
                        int(100 * room.area), room.motorbike, room.car,
                        room.room, int(100 * room.area), room.motorbike, room.car,
                    ) for room in rooms
                ]

                # https://github.com/aio-libs/aioodbc/issues/423
                cursor._impl.fast_executemany = True
                await cursor.executemany(
                    """
                    IF EXISTS (SELECT * FROM rooms WHERE room = ?)
                        UPDATE rooms
                        SET area = ?, motorbike = ?, car = ?
                        WHERE room = ?
                    ELSE
                        INSERT INTO rooms
                        VALUES (?, ?, ?, ?)
                    """,
                    params,
                )

    @staticmethod
    async def delete_many(rooms: List[int]) -> None:
        """This function is a coroutine.

        Delete room information from the database.

        Parameters
        -----
        rooms: `List[int]`
            A list of room numbers to delete.
        """
        if len(rooms) == 0:
            return

        async with Database.instance.pool.acquire() as connection:
            temp_fmt = ", ".join("?" for _ in rooms)

            async with connection.cursor() as cursor:
                await cursor.executemany(
                    f"DELETE FROM rooms WHERE room IN {temp_fmt}",
                    *rooms,
                )
