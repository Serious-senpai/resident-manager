from __future__ import annotations

from typing import Any, List, Optional

import pydantic

from ..database import Database
from ...config import DB_PAGINATION_QUERY


__all__ = ("RoomData", "Room")


class RoomData(pydantic.BaseModel):
    """Data model for objects holding room information.

    Each object of this class corresponds to a database row.
    """
    room: int
    area: float
    motorbike: int
    car: int

    @staticmethod
    async def update_many(rooms: List[RoomData]) -> None:
        """This function is a coroutine.

        Update room information in the database.

        Parameters
        -----
        rooms: `List[RoomData]`
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
                        room.room,
                        room.room, int(100 * room.area), room.motorbike, room.car,
                    ) for room in rooms
                ]

                # https://github.com/aio-libs/aioodbc/issues/423
                cursor._impl.fast_executemany = True
                await cursor.executemany(
                    """
                    IF EXISTS (SELECT 1 FROM rooms WHERE room = ?)
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

        temp_fmt = ", ".join("?" for _ in rooms)
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.executemany(
                    f"DELETE FROM rooms WHERE room IN {temp_fmt}",
                    *rooms,
                )


class Room(pydantic.BaseModel):
    """Data model for objects holding room information.

    Each object of this class does not correspond to a database row, but instead corresponds to
    a record obtained from a JOIN query.
    """

    room: int
    area: Optional[float]
    motorbike: Optional[int]
    car: Optional[int]
    residents: int

    @classmethod
    def from_row(cls, row: Any) -> Room:
        return cls(
            room=row[0],
            area=None if row[1] is None else row[1] / 100,
            motorbike=None if row[2] is None else row[2],
            car=None if row[3] is None else row[3],
            residents=row[4],
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

        query = [
            """
            WITH rooms_union AS (
                SELECT r1.room FROM rooms r1
                UNION ALL
                SELECT DISTINCT r2.room FROM residents r2
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM rooms
                    WHERE rooms.room = r2.room
                )
            )
            SELECT count(room) FROM rooms_union
            """,
        ]
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

                query = [
                    """
                    WITH rooms_union AS (
                        SELECT r1.room, r1.area, r1.motorbike, r1.car
                        FROM rooms r1
                        UNION ALL
                        SELECT DISTINCT r2.room, NULL AS area, NULL AS motorbike, NULL AS car
                        FROM residents r2
                        WHERE NOT EXISTS (
                            SELECT 1
                            FROM rooms
                            WHERE rooms.room = r2.room
                        )
                    )
                    SELECT ru.room, ru.area, ru.motorbike, ru.car, COUNT(residents.resident_id) AS residents
                    FROM rooms_union ru
                    LEFT JOIN residents ON ru.room = residents.room
                    GROUP BY ru.room, ru.area, ru.motorbike, ru.car
                    """,
                ]

                if len(where) > 0:
                    query.append("WHERE " + " AND ".join(where))

                query.append("ORDER BY ru.room OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]
