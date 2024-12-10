from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated, List, Literal, Optional

from fastapi import Depends, Query, Response, status
from pydantic import BeforeValidator

from ....app import api_v1
from ....models import AdminPermission, Fee, Result
from .....config import EPOCH


__all__ = ("admin_fees",)


@api_v1.get(
    "/admin/fees",
    name="Fee query",
    description="Query a list of fees",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "List of fees",
            "model": Result[List[Fee]],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_200_OK,
)
async def admin_fees(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    *,
    offset: int = 0,
    created_after: Annotated[
        datetime,
        Query(description="Query requests created after this timestamp"),
    ] = EPOCH,
    created_before: Annotated[
        datetime,
        Query(
            description="Query requests created before this timestamp",
            default_factory=lambda: datetime.now(timezone.utc),
        ),
    ],
    name: Optional[str] = None,
    order_by: Annotated[Literal[1, -1, 2, -2, 3, -3, 4, -4, 5, -5, 6, -6, 7, -7, 8, -8], BeforeValidator(int)] = -1,
) -> Result[Optional[List[Fee]]]:
    if admin.admin:
        return Result(
            data=await Fee.query(
                offset=offset,
                created_after=created_after,
                created_before=created_before,
                name=name,
                order_by=order_by,
            )
        )

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
