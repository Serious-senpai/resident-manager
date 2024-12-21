from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated, List, Optional

from fastapi import Depends, Query, Response, status

from .....app import api_v1
from .....models import AdminPermission, PaymentStatus, Result
from ......config import EPOCH


__all__ = ("admin_fees_payments",)


@api_v1.get(
    "/admin/fees/payments",
    name="Payment query",
    description="Query a list of payments",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "List of payments",
            "model": Result[List[PaymentStatus]],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_200_OK,
)
async def admin_fees_payments(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    *,
    room: Annotated[Optional[int], Query(description="Query payments associated to this room only")] = None,
    paid: Annotated[Optional[bool], Query(description="Whether to query paid or unpaid fees only")] = None,
    offset: Annotated[int, Query(description="Query offset")] = 0,
    created_after: Annotated[
        datetime,
        Query(description="Query fees created after this timestamp"),
    ] = EPOCH,
    created_before: Annotated[
        datetime,
        Query(
            description="Query fees created before this timestamp",
            default_factory=lambda: datetime.now(timezone.utc),
        ),
    ],
) -> Result[Optional[List[PaymentStatus]]]:
    if admin.admin:
        return await PaymentStatus.query(
            room,
            offset=offset,
            paid=paid,
            created_after=created_after,
            created_before=created_before,
        )

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
