from __future__ import annotations

import asyncio
from pathlib import Path
from typing import Any, ClassVar, Optional, TYPE_CHECKING

import aioodbc  # type: ignore

from .config import (
    DEFAULT_ADMIN_PASSWORD,
    DEFAULT_ADMIN_USERNAME,
    EPOCH,
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

        async def execute(file: Path, *args: Any) -> None:
            try:
                async with pool.acquire() as connection:
                    async with connection.cursor() as cursor:
                        with file.open("r", encoding="utf-8") as sql:
                            await cursor.execute(sql.read(), *args)

            except Exception as e:
                raise RuntimeError(f"Failed to execute {file}") from e

        scripts_dir = ROOT / "scripts"
        tasks = [
            asyncio.create_task(
                execute(
                    scripts_dir / "database.sql",
                    DEFAULT_ADMIN_USERNAME,
                    hash_password(DEFAULT_ADMIN_PASSWORD),
                    EPOCH,
                ),
            ),
        ]

        procedures = scripts_dir / "procedures"
        for file in procedures.iterdir():
            if file.suffix == ".sql":
                tasks.append(asyncio.create_task(execute(file)))

        await asyncio.gather(*tasks)

    async def close(self) -> None:
        if self.__pool is not None:
            self.__pool.close()
            await self.__pool.wait_closed()

        self.__prepared = False
        self.__pool = None


Database.instance = Database()
