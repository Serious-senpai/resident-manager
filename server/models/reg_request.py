from __future__ import annotations

import itertools
import re
from datetime import datetime
from typing import Any, List, Literal, Optional, overload

from .auth import HashedAuthorization
from .info import PublicInfo
from .snowflake import Snowflake
from ..config import DB_PAGINATION_QUERY
from ..database import Database
from ..errors import BadRequest, UsernameConflictError
from ..utils import generate_id, hash_password


__all__ = ("RegisterRequest",)


class RegisterRequest(PublicInfo, HashedAuthorization):
    """Data model for objects holding information about a registration request.

    Each object of this class corresponds to a database row."""

    @classmethod
    def from_row(cls, row: Any) -> RegisterRequest:
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

    async def accept(self) -> Snowflake:
        """This function is a coroutine.

        Accept the registration request, create a new resident record in the database
        and remove this request from the database.

        Returns
        -----
        `Snowflake`
            The newly registered resident as a `Snowflake` object.
        """
        async with Database.instance.pool.acquire() as connection:
            id = generate_id()
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                    DELETE FROM register_queue
                    OUTPUT ?, DELETED.name, DELETED.room, DELETED.birthday, DELETED.phone, DELETED.email, DELETED.username, DELETED.hashed_password
                    INTO residents
                    WHERE request_id = ?
                    """,
                    id,
                    self.id,
                )

        return Snowflake(id=id)

    async def decline(self) -> None:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("DELETE FROM register_queue WHERE request_id = ?", self.id)

    @staticmethod
    async def count() -> int:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("SELECT COUNT(*) FROM register_queue")
                return await cursor.fetchval()

    @classmethod
    async def accept_many(cls, ids: List[int]) -> None:
        if len(ids) == 0:
            return

        async with Database.instance.pool.acquire() as connection:
            mapping = [(generate_id(), id) for id in ids]
            temp_fmt = ", ".join("(?, ?)" for _ in mapping)
            temp_decl = f"(VALUES {temp_fmt}) temp(resident_id, request_id)"

            async with connection.cursor() as cursor:
                await cursor.execute(
                    f"""
                    DELETE FROM register_queue
                    OUTPUT temp.resident_id, DELETED.name, DELETED.room, DELETED.birthday, DELETED.phone, DELETED.email, DELETED.username, DELETED.hashed_password
                    INTO residents
                    FROM register_queue
                    INNER JOIN {temp_decl}
                    ON register_queue.request_id = temp.request_id
                    """,
                    *itertools.chain(*mapping),
                )

    @classmethod
    async def reject_many(cls, ids: List[int]) -> None:
        if len(ids) == 0:
            return

        async with Database.instance.pool.acquire() as connection:
            temp_fmt = ", ".join("?" for _ in ids)

            async with connection.cursor() as cursor:
                await cursor.execute(f"DELETE FROM register_queue WHERE request_id IN ({temp_fmt})", *ids)

    @overload
    @classmethod
    async def create(
        cls,
        name: str,
        room: int,
        birthday: Optional[datetime],
        phone: Optional[str],
        email: Optional[str],
        username: str,
        password: str,
        *,
        raise_http_exception: Literal[False],
    ) -> Optional[RegisterRequest]: ...

    @overload
    @classmethod
    async def create(
        cls,
        name: str,
        room: int,
        birthday: Optional[datetime],
        phone: Optional[str],
        email: Optional[str],
        username: str,
        password: str,
        *,
        raise_http_exception: Literal[True] = True,
    ) -> RegisterRequest: ...

    @classmethod
    async def create(
        cls,
        name: str,
        room: int,
        birthday: Optional[datetime],
        phone: Optional[str],
        email: Optional[str],
        username: str,
        password: str,
        *,
        raise_http_exception: bool = True,
    ) -> Optional[RegisterRequest]:
        # Validate data
        if phone is not None and len(phone) == 0:
            phone = None

        if email is not None and len(email) == 0:
            email = None

        if (
            len(name) == 0
            or len(name) > 255
            or room < 0
            or room > 32767
            or (phone is not None and (len(phone) > 15 or not phone.isdigit()))
            or (email is not None and len(email) > 255)
            or len(username) == 0
            or len(username) > 255
            or len(password) < 8
        ):
            if raise_http_exception:
                raise BadRequest

            return None

        if email is not None and re.fullmatch(r"[\w\.-]+@[\w\.-]+\.[\w\.]+[\w\.]?", email) is None:
            if raise_http_exception:
                raise BadRequest

            return None

        hashed_password = hash_password(password)
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                    IF NOT EXISTS (
                        SELECT username FROM residents WHERE username = ?
                        UNION
                        SELECT username FROM register_queue WHERE username = ?
                    )
                    INSERT INTO register_queue OUTPUT INSERTED.* VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    username,
                    username,
                    generate_id(),
                    name,
                    room,
                    birthday,
                    phone,
                    email,
                    username,
                    hashed_password,
                )
                row = await cursor.fetchone()
                if row is not None:
                    return cls.from_row(row)

        if raise_http_exception:
            raise UsernameConflictError

        return None

    @classmethod
    async def query(
        cls,
        *,
        offset: int = 0,
        id: Optional[int] = None,
        name: Optional[str] = None,
        room: Optional[int] = None,
        username: Optional[str] = None,
    ) -> List[RegisterRequest]:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                where: List[str] = []
                params: List[Any] = []

                if id is not None:
                    where.append("request_id = ?")
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

                query = ["SELECT * FROM register_queue"]
                if len(where) > 0:
                    query.append("WHERE " + " AND ".join(where))

                query.append("ORDER BY request_id DESC OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]
