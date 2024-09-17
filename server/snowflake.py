from __future__ import annotations

from datetime import datetime, timedelta
from typing import TYPE_CHECKING

from .utils import from_epoch


__all__ = ("Snowflake",)


class Snowflake:

    __slots__ = ("id",)
    if TYPE_CHECKING:
        id: int

    def __init__(self, *, id: int) -> None:
        self.id = id

    @property
    def created_at(self) -> datetime:
        return from_epoch(timedelta(milliseconds=self.id >> 14))
