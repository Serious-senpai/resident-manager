from __future__ import annotations

from typing import Annotated, Generic, Optional, TypeVar

import pydantic


__all__ = ("Result",)
_SerializableT = TypeVar("_SerializableT", covariant=True)


class Result(pydantic.BaseModel, Generic[_SerializableT]):
    """Response model for all API results"""

    code: Annotated[int, pydantic.Field(description="The result code of the operation")] = 0
    data: Annotated[_SerializableT, pydantic.Field(description="The result data of the operation")]
