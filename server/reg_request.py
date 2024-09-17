from __future__ import annotations

from datetime import datetime
from typing import Optional, TYPE_CHECKING

import aioodbc  # type: ignore  # dead PR: https://github.com/aio-libs/aioodbc/pull/429

from .database import Database
from .personal import PersonalInfo
from .residents import Resident
from .utils import generate_id, snowflake_time


__all__ = ("RegisterRequest",)


class RegisterRequest(PersonalInfo):

    __slots__ = (
        "id",
    )
    if TYPE_CHECKING:
        id: int

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
        super().__init__(
            name=name,
            room=room,
            birthday=birthday,
            phone=phone,
            email=email,
            username=username,
            hashed_password=hashed_password,
        )

        self.id = id

    @property
    def created_at(self) -> datetime:
        return snowflake_time(self.id)

    async def __remove_from_db(self, *, cursor: aioodbc.Cursor) -> None:
        await cursor.execute("DELETE FROM register_queue WHERE request_id = ?", self.id)

    async def accept(self) -> Resident:
        """This function is a coroutine.

        Accept the registration request, create a new resident record in the database
        and remove this request from the database.

        Returns
        -----
        `Resident`
            The newly registered resident.
        """
        database = Database()
        await database.prepare()

        async with database.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                resident_id = generate_id()
                await cursor.execute(
                    """
                    INSERT INTO residents SELECT *, ? FROM register_queue WHERE request_id = ?;
                    DECLARE @Id INT = SCOPE_IDENTITY();
                    SELECT * FROM residents WHERE ID = @Id;
                    """,
                    resident_id,
                    self.id,
                )

                row = await cursor.fetchone()
                resident = Resident.from_row(row)

                await self.__remove_from_db(cursor=cursor)

        return resident

    async def decline(self) -> None:
        database = Database()
        await database.prepare()

        async with database.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await self.__remove_from_db(cursor=cursor)

    @classmethod
    async def create(
        cls,
        name: str,
        room: int,
        birthday: Optional[datetime],
        phone: Optional[str],
        email: Optional[str],
        username: str,
        hashed_password: str,
    ) -> RegisterRequest:
        database = Database()
        await database.prepare()

        async with database.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                request_id = generate_id()
                await cursor.execute(
                    "INSERT INTO register_queue VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
                    request_id,
                    name,
                    room,
                    birthday,
                    phone,
                    email,
                    username,
                    hashed_password,
                )

        return cls(
            id=request_id,
            name=name,
            room=room,
            birthday=birthday,
            phone=phone,
            email=email,
            username=username,
            hashed_password=hashed_password,
        )
