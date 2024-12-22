from __future__ import annotations

import itertools
from datetime import datetime, timezone
from typing import Annotated, List, Literal, Optional, TypeVar

import jwt
from fastapi import Depends
from fastapi.security import OAuth2PasswordRequestForm

from .accounts import Account
from .auth import Token, ALGORITHM, secret_key
from .info import PersonalInfo
from .results import Result
from .snowflake import Snowflake
from ...config import DB_PAGINATION_QUERY, EPOCH
from ...database import Database
from ...utils import (
    check_password,
    hash_password,
    validate_password,
    validate_username,
)


__all__ = ("Resident",)
T = TypeVar("T")


class Resident(Account):
    """Data model for objects holding information about a resident.

    Each object of this class corresponds to a database row."""

    async def update_authorization(self, username: str, password: str) -> Result[Optional[Resident]]:
        if not validate_username(username):
            return Result(code=105, data=None)

        if not validate_password(password):
            return Result(code=106, data=None)

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "EXECUTE UpdateResidentAuthorization @Id = ?, @Username = ?, @HashedPassword = ?",
                    self.id,
                    username,
                    hash_password(password),
                )

                row = await cursor.fetchone()
                if row is not None:
                    return Result(data=Resident.from_row(row))

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
    ) -> List[Resident]:
        _packed = Account.build_sql_condition(id=id, name=name, room=room, username=username)
        if _packed is None:
            return []

        where, params = _packed
        where.append("approved = 1")

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

    @classmethod
    async def delete_many(cls, objects: List[Snowflake]) -> None:
        if len(objects) == 0:
            return

        for batch in itertools.batched(objects, 1000):
            array = ", ".join(itertools.repeat("(?)", len(batch)))
            async with Database.instance.pool.acquire() as connection:
                async with connection.cursor() as cursor:
                    await cursor.execute(
                        f"""
                            DECLARE @Id BIGINTARRAY
                            INSERT INTO @Id VALUES {array}
                            EXECUTE DeleteResidents @Id = @Id
                        """,
                        *[o.id for o in batch],
                    )

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
                    1,
                )

                return await cursor.fetchval()

    @classmethod
    async def create_token(cls, form_data: OAuth2PasswordRequestForm) -> Optional[Token]:
        residents = await cls.query(username=form_data.username)
        if len(residents) == 0:
            return None

        resident = residents[0]
        if not check_password(form_data.password, hashed=resident.hashed_password):
            return None

        return Token.create(Snowflake(id=resident.id), secret_key=await secret_key())

    @classmethod
    async def from_token(cls, token: Annotated[str, Depends(Token.oauth2_resident)]) -> Result[Optional[Resident]]:
        try:
            payload = jwt.decode(token, await secret_key(), algorithms=[ALGORITHM], options={"require": ["exp"]})
            snowflake = Snowflake.model_validate(payload)

            residents = await Resident.query(id=snowflake.id)
            if len(residents) == 1:
                return Result(data=residents[0])

        except Exception:
            pass

        return Result(code=201, data=None)

    @classmethod
    async def update(cls, *, id: int, info: PersonalInfo) -> Result[Optional[Resident]]:
        result = info.validate_info()
        if result is not None:
            return result

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                        EXECUTE UpdateResident
                            @Id = ?,
                            @Name = ?,
                            @Room = ?,
                            @Birthday = ?,
                            @Phone = ?,
                            @Email = ?
                    """,
                    id,
                    info.name,
                    info.room,
                    info.birthday,
                    info.phone,
                    info.email,
                )

                row = await cursor.fetchone()
                if row is not None:
                    return Result(data=cls.from_row(row))

        return Result(code=301, data=None)
