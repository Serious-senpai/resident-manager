from __future__ import annotations

from typing import ClassVar, Optional, TYPE_CHECKING

import aioodbc  # type: ignore

from .config import (
    DEFAULT_ADMIN_HASHED_PASSWORD,
    DEFAULT_ADMIN_USERNAME,
    ODBC_CONNECTION_STRING,
)


__all__ = ("Database",)


class Database:

    __instance__: ClassVar[Optional[Database]] = None
    __slots__ = (
        "__pool",
        "__prepared",
    )
    if TYPE_CHECKING:
        __pool: Optional[aioodbc.Pool]
        __prepared: bool

    def __new__(cls) -> Database:
        if cls.__instance__ is None:
            self = super().__new__(cls)

            self.__pool = None
            self.__prepared = False

            cls.__instance__ = self

        return cls.__instance__

    @property
    def pool(self) -> aioodbc.Pool:
        if self.__pool is None:
            raise RuntimeError("Database is not connected. Did you call `.prepare()`?")

        return self.__pool

    async def prepare(self) -> None:
        if self.__prepared:
            return

        self.__prepared = True

        self.__pool = pool = await aioodbc.create_pool(
            dsn=ODBC_CONNECTION_STRING,
            minsize=1,
            maxsize=10,
            autocommit=True,
        )

        async with pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("""
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'residents')
                    CREATE TABLE residents (
                        resident_id BIGINT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        room SMALLINT NOT NULL,
                        birthday DATETIME,
                        phone VARCHAR(15),
                        email VARCHAR(15),
                        username VARCHAR(255) UNIQUE NOT NULL,
                        hashed_password VARCHAR(255) NOT NULL,
                    )
                """)
                await cursor.execute("""
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'register_queue')
                    CREATE TABLE register_queue (
                        request_id BIGINT PRIMARY KEY,
                        name VARCHAR(255) NOT NULL,
                        room SMALLINT NOT NULL,
                        birthday DATETIME,
                        phone VARCHAR(15),
                        email VARCHAR(15),
                        username VARCHAR(255) UNIQUE NOT NULL,
                        hashed_password VARCHAR(255) NOT NULL,
                    )
                """)
                await cursor.execute(
                    """
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'config')
                    BEGIN
                        CREATE TABLE config (
                            name VARCHAR(255) primary key,
                            value VARCHAR(255) NOT NULL,
                        )
                        INSERT INTO config VALUES ('admin_username', ?)
                        INSERT INTO config VALUES ('admin_hashed_password', ?)
                    END
                    """,
                    DEFAULT_ADMIN_USERNAME,
                    DEFAULT_ADMIN_HASHED_PASSWORD,
                )
