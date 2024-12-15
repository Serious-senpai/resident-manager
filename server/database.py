from __future__ import annotations

import atexit
import logging
import os
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
logger = logging.getLogger("uvicorn")


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
            minsize=10,
            maxsize=100,
            autocommit=True,
        )

        lock_file = ROOT / "database.lock"
        try:
            fd = os.open(str(lock_file), os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            os.close(fd)
        except FileExistsError:
            return
        else:
            atexit.register(lock_file.unlink, missing_ok=True)

        async with pool.acquire() as connection:
            async with connection.cursor() as cursor:

                async def execute(file: Path, *args: Any) -> None:
                    try:
                        logger.info(f"Executing {file}")
                        with file.open("r", encoding="utf-8") as sql:
                            await cursor.execute(sql.read(), *args)

                    except Exception as e:
                        raise RuntimeError(f"Failed to execute {file}") from e

                scripts_dir = ROOT / "scripts"
                await execute(
                    scripts_dir / "database.sql",
                    DEFAULT_ADMIN_USERNAME,
                    hash_password(DEFAULT_ADMIN_PASSWORD),
                    EPOCH,
                )

                procedures = scripts_dir / "procedures"
                for file in procedures.iterdir():
                    if file.suffix == ".sql":
                        await execute(file)

    async def close(self) -> None:
        if self.__pool is not None:
            logger.info("Closing database connection pool")
            self.__pool.close()
            await self.__pool.wait_closed()

        self.__prepared = False
        self.__pool = None


Database.instance = Database()
