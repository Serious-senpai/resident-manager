from __future__ import annotations

from typing import Generic, Optional, TypeVar

import pydantic


__all__ = ("Result",)
_SerializableT = TypeVar("_SerializableT", covariant=True)


class Result(pydantic.BaseModel, Generic[_SerializableT]):
    """Response model for all API results"""

    code: int = 0
    data: Optional[_SerializableT]
