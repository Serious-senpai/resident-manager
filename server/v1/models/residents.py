from __future__ import annotations

import itertools
from typing import Annotated, Any, List, Literal, Optional, TypeVar

import jwt
from fastapi import Depends
from fastapi.security import OAuth2PasswordRequestForm
from jwt.exceptions import PyJWTError

from .auth import HashedAuthorization, Token
from .info import PersonalInfo, PublicInfo
from .results import Result
from .snowflake import Snowflake
from ..database import Database
from ..utils import (
    check_password,
    validate_name,
    validate_room,
    validate_username,
)
from ...config import DB_PAGINATION_QUERY


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

        temp_fmt = ", ".join(itertools.repeat("?", len(objects)))
        async with Database.instance.pool.acquire() as connection:
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
    async def create_token(cls, form_data: OAuth2PasswordRequestForm) -> Optional[Token]:
        residents = await cls.query(username=form_data.username)
        if len(residents) == 0:
            return None

        resident = residents[0]
        if not check_password(form_data.password, hashed=resident.hashed_password):
            return None

        return Token.create(Snowflake(id=resident.id))

    @classmethod
    async def from_token(cls, token: Annotated[str, Depends(Token.oauth2_resident)]) -> Result[Optional[Resident]]:
        try:
            payload = jwt.decode(token, Token.SECRET_KEY, algorithms=[Token.ALGORITHM])
            snowflake = Snowflake.model_validate(payload)

            residents = await Resident.query(id=snowflake.id)
            if len(residents) == 1:
                return Result(data=residents[0])

        except PyJWTError:
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

        return Result(code=301, data=None)
