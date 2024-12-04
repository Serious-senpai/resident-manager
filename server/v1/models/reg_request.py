from __future__ import annotations

import itertools
from datetime import date, datetime, timezone
from typing import List, Literal, Optional

from .accounts import Account
from .results import Result
from .snowflake import Snowflake
from ...config import DB_PAGINATION_QUERY, EPOCH
from ...database import Database
from ...utils import (
    hash_password,
    validate_name,
    validate_room,
    validate_phone,
    validate_email,
    validate_username,
    validate_password,
)


__all__ = ("RegisterRequest",)


class RegisterRequest(Account):
    """Data model for objects holding information about a registration request.

    Each object of this class corresponds to a database row."""

    @staticmethod
    async def count(
        *,
        created_after: datetime,
        created_before: datetime,
        name: Optional[str] = None,
        room: Optional[int] = None,
        username: Optional[str] = None,
    ) -> int:
        created_after = max(created_after.astimezone(timezone.utc), EPOCH)
        created_before = max(created_before.astimezone(timezone.utc), EPOCH)

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                        EXECUTE CountAccounts
                            @CreatedAfter = ?,
                            @CreatedBefore = ?,
                            @Name = ?,
                            @Room = ?,
                            @Username = ?,
                            @Approved = ?
                    """,
                    created_after,
                    created_before,
                    name,
                    room,
                    username,
                    0,
                )

                return await cursor.fetchval()

    @classmethod
    async def accept_many(cls, objects: List[Snowflake]) -> None:
        if len(objects) == 0:
            return

        array = ", ".join(itertools.repeat("(?)", len(objects)))
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    f"""
                        DECLARE @Id BIGINTARRAY
                        INSERT INTO @Id VALUES {array}
                        EXECUTE ApproveRegistrationRequests @Id = @Id
                    """,
                    *[o.id for o in objects],
                )

    @classmethod
    async def reject_many(cls, objects: List[Snowflake]) -> None:
        if len(objects) == 0:
            return

        array = ", ".join(itertools.repeat("(?)", len(objects)))
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    f"""
                        DECLARE @Id BIGINTARRAY
                        INSERT INTO @Id VALUES {array}
                        EXECUTE RejectRegistrationRequests @Id = @Id
                    """,
                    *[o.id for o in objects],
                )

    @classmethod
    async def create(
        cls,
        *,
        name: str,
        room: int,
        birthday: Optional[date],
        phone: Optional[str],
        email: Optional[str],
        username: str,
        password: str,
    ) -> Result[Optional[RegisterRequest]]:
        # Validate data
        if phone is None or len(phone) == 0:
            phone = None

        if email is None or len(email) == 0:
            email = None

        if not validate_name(name):
            return Result(code=101, data=None)

        if not validate_room(room):
            return Result(code=102, data=None)

        if phone is not None and not validate_phone(phone):
            return Result(code=103, data=None)

        if email is not None and not validate_email(email):
            return Result(code=104, data=None)

        if not validate_username(username):
            return Result(code=105, data=None)

        if not validate_password(password):
            return Result(code=106, data=None)

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                        EXECUTE Register
                            @Name = ?,
                            @Room = ?,
                            @Birthday = ?,
                            @Phone = ?,
                            @Email = ?,
                            @Username = ?,
                            @HashedPassword = ?
                    """,
                    name,
                    room,
                    birthday,
                    phone,
                    email,
                    username,
                    hash_password(password),
                )

                row = await cursor.fetchone()
                if row is not None:
                    return Result(data=cls.from_row(row))

        return Result(code=107, data=None)

    @classmethod
    async def query(
        cls,
        *,
        offset: int = 0,
        id: Optional[int] = None,
        name: Optional[str] = None,
        room: Optional[int] = None,
        username: Optional[str] = None,
        order_by: Literal["id", "name", "room", "username"] = "id",
        ascending: bool = True,
    ) -> List[RegisterRequest]:
        _packed = Account.build_sql_condition(id=id, name=name, room=room, username=username)
        if _packed is None:
            return []

        where, params = _packed
        where.append("approved = 0")

        query = [
            "SELECT * FROM accounts",
            "WHERE " + " AND ".join(where),
        ]

        if order_by not in {"id", "name", "room", "username"}:
            order_by = "id"

        asc_desc = "ASC" if ascending else "DESC"
        query.append(f"ORDER BY {order_by} {asc_desc} OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]
