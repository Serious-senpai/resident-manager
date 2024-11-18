from __future__ import annotations

from typing import ClassVar, Optional, TYPE_CHECKING

import aioodbc  # type: ignore

from .config import (
    DEFAULT_ADMIN_PASSWORD,
    DEFAULT_ADMIN_USERNAME,
    ODBC_CONNECTION_STRING,
    ROOT,
)
from .utils import hash_password


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
                with open(ROOT / "scripts" / "tables.sql", "r", encoding="utf-8") as sql:
                    await cursor.execute(
                        sql.read(),
                        DEFAULT_ADMIN_USERNAME,
                        hash_password(DEFAULT_ADMIN_PASSWORD),
                    )

    async def close(self) -> None:
        if self.__pool is not None:
            self.__pool.close()
            await self.__pool.wait_closed()

        self.__prepared = False
        self.__pool = None


Database.instance = Database()
