from __future__ import annotations

from typing import ClassVar, Optional, TYPE_CHECKING

import aioodbc  # type: ignore

from .config import ODBC_CONNECTION_STRING


__all__ = ("Database",)


class Database:

    __instance__: ClassVar[Optional[Database]] = None
    __slots__ = ("__pool",)
    if TYPE_CHECKING:
        __pool: Optional[aioodbc.Pool]

    def __new__(cls) -> Database:
        if cls.__instance__ is None:
            self = super().__new__(cls)
            self.__pool = None

            cls.__instance__ = self

        return cls.__instance__

    def pool(self) -> aioodbc.Pool:
        if self.__pool is None:
            raise RuntimeError("Database is not connected. Did you call `.prepare()`?")

        return self.__pool

    async def prepare(self) -> None:
        self.__pool = await aioodbc.create_pool(
            dsn=ODBC_CONNECTION_STRING,
            minsize=1,
            maxsize=10,
            autocommit=True,
        )
