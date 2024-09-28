from __future__ import annotations

from typing import ClassVar, Optional, TYPE_CHECKING

import aioodbc  # type: ignore

from .config import (
    DEFAULT_ADMIN_PASSWORD,
    DEFAULT_ADMIN_USERNAME,
    ODBC_CONNECTION_STRING,
)
from .errors import AuthenticationRequired
from .utils import check_password, hash_password


__all__ = ("Database",)


class Database:
    """A database singleton that manages the connection pool."""

    instance: ClassVar[Database]
    __slots__ = (
        "__pool",
        "__prepared",
    )
    if TYPE_CHECKING:
        __pool: Optional[aioodbc.Pool]
        __prepared: bool

    def __init__(self) -> None:
        self.__pool = None
        self.__prepared = False

    @property
    def pool(self) -> aioodbc.Pool:
        """The underlying connection pool.

        In order to use this property, `.prepare()` must be called first.
        """
        if self.__pool is None:
            raise RuntimeError("Database is not connected. Did you call `.prepare()`?")

        return self.__pool

    async def prepare(self) -> None:
        """This function is a coroutine.

        Prepare the underlying connection pool. If the pool is already created, this function does nothing.
        """
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
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'residents' AND type = 'U')
                    CREATE TABLE residents (
                        resident_id BIGINT PRIMARY KEY,
                        name NVARCHAR(255) COLLATE Vietnamese_100_CS_AS_KS_WS_SC_UTF8 NOT NULL,
                        room SMALLINT NOT NULL,
                        birthday DATETIME,
                        phone NVARCHAR(15),
                        email NVARCHAR(255),
                        username NVARCHAR(255) UNIQUE NOT NULL,
                        hashed_password NVARCHAR(255) NOT NULL,
                    )
                """)
                await cursor.execute("""
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'register_queue' AND type = 'U')
                    CREATE TABLE register_queue (
                        request_id BIGINT PRIMARY KEY,
                        name NVARCHAR(255) COLLATE Vietnamese_100_CS_AS_KS_WS_SC_UTF8 NOT NULL,
                        room SMALLINT NOT NULL,
                        birthday DATETIME,
                        phone NVARCHAR(15),
                        email NVARCHAR(255),
                        username NVARCHAR(255) UNIQUE NOT NULL,
                        hashed_password NVARCHAR(255) NOT NULL,
                    )
                """)
                await cursor.execute(
                    """
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'config' AND type = 'U')
                    BEGIN
                        CREATE TABLE config (
                            name NVARCHAR(255) PRIMARY KEY,
                            value NVARCHAR(255) NOT NULL,
                        )
                        INSERT INTO config VALUES ('admin_username', ?)
                        INSERT INTO config VALUES ('admin_hashed_password', ?)
                    END
                    """,
                    DEFAULT_ADMIN_USERNAME,
                    hash_password(DEFAULT_ADMIN_PASSWORD),
                )

                # Fee lower, upper = [VND] * 100
                await cursor.execute("""
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'fee' AND type = 'U')
                    CREATE TABLE fee (
                        fee_id BIGINT PRIMARY KEY,
                        name NVARCHAR(255) COLLATE Vietnamese_100_CS_AS_KS_WS_SC_UTF8 NOT NULL,
                        lower INT NOT NULL,
                        upper INT NOT NULL,
                        date DATETIME NOT NULL,
                        description NVARCHAR(max) COLLATE Vietnamese_100_CS_AS_KS_WS_SC_UTF8,
                        flags TINYINT NOT NULL,
                        CHECK (lower <= upper),
                    )
                """)

                # Room area = [area in m2] * 100
                await cursor.execute("""
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'rooms' AND type = 'U')
                    CREATE TABLE rooms (
                        room SMALLINT PRIMARY KEY,
                        area INT NOT NULL,
                        motorbike TINYINT NOT NULL,
                        car TINYINT NOT NULL,
                    )
                """)

                # Payment amount = [VND] * 100
                await cursor.execute("""
                    IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'payments' AND type = 'U')
                    CREATE TABLE payments (
                        payment_id BIGINT PRIMARY KEY,
                        room SMALLINT NOT NULL,
                        amount INT NOT NULL,
                    )
                """)

    async def close(self) -> None:
        if self.__pool is not None:
            self.__pool.close()
            await self.__pool.wait_closed()

        self.__prepared = False
        self.__pool = None

    async def verify_admin(self, username: str, password: str, *, raise_http_exception: bool = True) -> bool:
        try:
            if self.__pool is None:
                raise AuthenticationRequired

            async with self.__pool.acquire() as connection:
                async with connection.cursor() as cursor:
                    await cursor.execute("SELECT * FROM config WHERE name = 'admin_username' OR name = 'admin_hashed_password'")
                    rows = await cursor.fetchall()

                    if len(rows) != 2:
                        raise RuntimeError("Invalid database format. Couldn't verify admin login.")

                    for name, value in rows:
                        if name == "admin_username":
                            if username != value:
                                raise AuthenticationRequired

                        else:
                            if not check_password(password, hashed=value):
                                raise AuthenticationRequired

        except AuthenticationRequired:
            if raise_http_exception:
                raise

            return False

        return True


Database.instance = Database()
