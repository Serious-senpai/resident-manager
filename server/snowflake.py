from __future__ import annotations

from typing import Protocol, runtime_checkable


__all__ = ("Snowflake",)


@runtime_checkable
class Snowflake(Protocol):
    """Base class for objects holding an ID."""
    id: int
