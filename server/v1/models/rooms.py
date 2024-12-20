from __future__ import annotations

import itertools
from typing import Annotated, List, Optional

import pydantic
from pyodbc import Row  # type: ignore

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

    @classmethod
    def from_row(cls, row: Row) -> RoomData:
        return cls(
            room=row.room,
            area=row.area / 100,
            motorbike=row.motorbike,
            car=row.car,
        )

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

        for batch in itertools.batched(rooms, 1000):
            array = ", ".join(itertools.repeat("(?)", len(batch)))
            async with Database.instance.pool.acquire() as connection:
                async with connection.cursor() as cursor:
                    await cursor.execute(
                        f"""
                            DECLARE @Rooms BIGINTARRAY
                            INSERT INTO @Rooms VALUES {array}
                            EXECUTE DeleteRoom @Rooms = @Rooms
                        """,
                        *batch,
                    )


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

    @property
    def has_data(self) -> bool:
        return self.area is not None and self.motorbike is not None and self.car is not None

    @classmethod
    def from_row(cls, row: Row) -> Room:
        return cls(
            room=row.room,
            area=None if row.area is None else row.area / 100,
            motorbike=row.motorbike,
            car=row.car,
            residents=row.residents,
        )

    @staticmethod
    async def count(
        *,
        room: Optional[int] = None,
        floor: Optional[int] = None,
    ) -> int:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("EXECUTE CountRooms @Room = ?, @Floor = ?", room, floor)
                return await cursor.fetchval()

    @classmethod
    async def query(
        cls,
        *,
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
                await cursor.execute(
                    """
                        EXECUTE QueryRooms
                            @Room = ?,
                            @Floor = ?,
                            @Offset = ?,
                            @FetchNext = ?
                    """,
                    room,
                    floor,
                    offset,
                    DB_PAGINATION_QUERY,
                )

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]
