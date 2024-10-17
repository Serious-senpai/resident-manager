from __future__ import annotations

from datetime import datetime
from typing import Any

import pydantic

from ..utils import snowflake_time


__all__ = ("Snowflake",)


class Snowflake(pydantic.BaseModel):
    """Data model for snowflake IDs"""

    id: int

    @property
    def created_at(self) -> datetime:
        """The time at which this snowflake was created"""
        return snowflake_time(self.id)

    def __eq__(self, other: Any) -> bool:
        if isinstance(other, Snowflake):
            return self.id == other.id

        return NotImplemented

    def __hash__(self) -> int:
        return hash(self.id)
