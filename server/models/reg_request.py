from __future__ import annotations

import itertools
from datetime import datetime
from typing import Any, List, Literal, Optional, overload

import pyodbc  # type: ignore

from .auth import HashedAuthorization
from .info import PublicInfo
from .snowflake import Snowflake
from ..config import DB_PAGINATION_QUERY
from ..database import Database
from ..errors import BadRequest, UsernameConflictError
from ..utils import (
    generate_id,
    hash_password,
    validate_name,
    validate_room,
    validate_phone,
    validate_email,
    validate_username,
    validate_password,
)


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
            where.append("request_id = ?")
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

        query = ["SELECT COUNT(request_id) FROM register_queue"]
        if len(where) > 0:
            query.append("WHERE " + " AND ".join(where))

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("\n".join(query), *params)
                return await cursor.fetchval()

    @classmethod
    async def accept_many(cls, objects: List[Snowflake]) -> None:
        if len(objects) == 0:
            return

        async with Database.instance.pool.acquire() as connection:
            mapping = [(generate_id(), o.id) for o in objects]
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
    async def reject_many(cls, objects: List[Snowflake]) -> None:
        if len(objects) == 0:
            return

        async with Database.instance.pool.acquire() as connection:
            temp_fmt = ", ".join("?" for _ in objects)

            async with connection.cursor() as cursor:
                await cursor.execute(f"DELETE FROM register_queue WHERE request_id IN ({temp_fmt})", *[o.id for o in objects])

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
        if phone is None or len(phone) == 0:
            phone = None

        if email is None or len(email) == 0:
            email = None

        if (
            not validate_name(name)
            or not validate_room(room)
            or (phone is not None and not validate_phone(phone))
            or (email is not None and not validate_email(email))
            or not validate_username(username)
            or not validate_password(password)
        ):
            if raise_http_exception:
                raise BadRequest

            return None

        hashed_password = hash_password(password)
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                    IF NOT EXISTS (
                        SELECT 1 FROM residents WHERE username = ?
                        UNION
                        SELECT 1 FROM register_queue WHERE username = ?
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

                try:
                    row = await cursor.fetchone()
                    if row is not None:
                        return cls.from_row(row)

                except pyodbc.ProgrammingError:
                    pass

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
        order_by: Literal["request_id", "name", "room", "username"] = "request_id",
        ascending: bool = True,
    ) -> List[RegisterRequest]:
        where: List[str] = []
        params: List[Any] = []

        if id is not None:
            where.append("request_id = ?")
            params.append(id)

        if name is not None:
            if not validate_name(name):
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

        query = ["SELECT * FROM register_queue"]
        if len(where) > 0:
            query.append("WHERE " + " AND ".join(where))

        if order_by not in {"request_id", "name", "room", "username"}:
            order_by = "request_id"

        asc_desc = "ASC" if ascending else "DESC"
        query.append(f"ORDER BY {order_by} {asc_desc} OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]
