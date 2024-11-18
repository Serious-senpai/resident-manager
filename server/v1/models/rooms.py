from __future__ import annotations

from typing import Annotated, Any, List, Optional

import pydantic

from .results import Result
from ...config import DB_PAGINATION_QUERY
from ...database import Database
from ...utils import validate_room


__all__ = ("RoomData", "Room")


class RoomData(pydantic.BaseModel):
    """Data model for objects holding room information.

    Each object of this class corresponds to a database row.
    """
    room: Annotated[int, pydantic.Field(description="The room number")]
    area: Annotated[float, pydantic.Field(description="The area of the room in square meters")]
    motorbike: Annotated[int, pydantic.Field(description="The number of motorbikes")]
    car: Annotated[int, pydantic.Field(description="The number of cars")]

    def validate_info(self) -> Optional[Result[None]]:
        if not validate_room(self.room):
            return Result(code=102, data=None)

        if self.area < 0 or self.area > 21474836:
            return Result(code=501, data=None)

        if self.motorbike < 0 or self.motorbike > 255:
            return Result(code=502, data=None)

        if self.car < 0 or self.car > 255:
            return Result(code=503, data=None)

        return None

    @staticmethod
    async def update_many(rooms: List[RoomData]) -> Optional[Result[None]]:
        """This function is a coroutine.

        Update room information in the database.

        Parameters
        -----
        rooms: `List[RoomData]`
            A list of room information objects to update.
        """
        if len(rooms) == 0:
            return None

        for room in rooms:
            validate = room.validate_info()
            if validate is not None:
                return validate

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                # https://github.com/aio-libs/aioodbc/issues/423
                cursor._impl.fast_executemany = True
                await cursor.executemany(
                    """
                    DECLARE
                        @Room SMALLINT = ?,
                        @Area INT = ?,
                        @Motorbike TINYINT = ?,
                        @Car TINYINT = ?

                    IF EXISTS (SELECT 1 FROM rooms WHERE room = @Room)
                        UPDATE rooms
                        SET area = @Area, motorbike = @Motorbike, car = @Car
                        WHERE room = @Room
                    ELSE
                        INSERT INTO rooms
                        VALUES (@Room, @Area, @Motorbike, @Car)
                    """,
                    [(r.room, int(100 * r.area), r.motorbike, r.car) for r in rooms],
                )

        return None

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

        array = "(" + ", ".join("?" * len(rooms)) + ")"
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(f"DELETE FROM rooms WHERE room IN {array}", *rooms)


class Room(pydantic.BaseModel):
    """Data model for objects holding room information.

    Each object of this class does not correspond to a database row, but instead corresponds to
    a record obtained from a JOIN query.
    """

    room: Annotated[int, pydantic.Field(description="The room number")]
    area: Annotated[Optional[float], pydantic.Field(description="The area of the room in square meters")]
    motorbike: Annotated[Optional[int], pydantic.Field(description="The number of motorbikes")]
    car: Annotated[Optional[int], pydantic.Field(description="The number of cars")]
    residents: Annotated[int, pydantic.Field(description="The number of residents in this room")]

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
                    SELECT t1.room FROM rooms t1
                    UNION ALL
                    SELECT DISTINCT t2.room FROM accounts t2
                    WHERE t2.approved = 1 AND NOT EXISTS (
                        SELECT 1
                        FROM rooms
                        WHERE rooms.room = t2.room
                    )
                )
                SELECT COUNT(1) FROM rooms_union
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
                having: List[str] = []
                params: List[Any] = []

                if room is not None:
                    having.append("ru.room = ?")
                    params.append(room)

                if floor is not None:
                    having.append("ru.room / 100 = ?")
                    params.append(floor)

                query = [
                    """
                        WITH rooms_union (room, area, motorbike, car) AS (
                            SELECT t1.room, t1.area, t1.motorbike, t1.car
                            FROM rooms t1
                            UNION ALL
                            SELECT DISTINCT t2.room, NULL, NULL, NULL
                            FROM accounts t2
                            WHERE t2.approved = 1 AND NOT EXISTS (
                                SELECT 1
                                FROM rooms
                                WHERE rooms.room = t2.room
                            )
                        )
                        SELECT ru.room, ru.area, ru.motorbike, ru.car, COUNT(1) AS residents
                        FROM rooms_union ru
                        LEFT JOIN accounts ON ru.room = accounts.room
                        GROUP BY ru.room, ru.area, ru.motorbike, ru.car
                    """,
                ]

                if len(having) > 0:
                    query.append("HAVING " + " AND ".join(having))

                query.append("ORDER BY ru.room OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]
