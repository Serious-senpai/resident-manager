from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated, Optional

from fastapi import Depends, Query, Response, status

from ....app import api_v1
from ....models import AdminPermission, Fee, Result
from .....config import EPOCH


__all__ = ("admin_fees_count",)


@api_v1.get(
    "/admin/fees/count",
    name="Fee count",
    description="Count the number of fees",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "Number of fees",
            "model": Result[int],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_200_OK,
)
async def admin_fees_count(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    *,
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
) -> Result[Optional[int]]:
    if admin.admin:
        return Result(
            data=await Fee.count(
                created_after=created_after,
                created_before=created_before,
                name=name,
            )
        )

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
