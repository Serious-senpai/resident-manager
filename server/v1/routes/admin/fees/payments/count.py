from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated, Optional

from fastapi import Depends, Query, Response, status

from .....app import api_v1
from .....models import AdminPermission, PaymentStatus, Result
from ......config import EPOCH


__all__ = ("admin_fees_payments_count",)


@api_v1.get(
    "/admin/fees/payments/count",
    name="Payment count",
    description="Count the number of payment status",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "Number of payment status",
            "model": Result[Optional[int]],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_200_OK,
)
async def admin_fees_payments_count(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    *,
    room: Annotated[Optional[int], Query(description="Count payments associated to this room only")] = None,
    paid: Annotated[Optional[bool], Query(description="Whether to count paid or unpaid status only")] = None,
    created_after: Annotated[
        datetime,
        Query(description="Count fees created after this timestamp"),
    ] = EPOCH,
    created_before: Annotated[
        datetime,
        Query(
            description="Count fees created before this timestamp",
            default_factory=lambda: datetime.now(timezone.utc),
        ),
    ],
) -> Result[Optional[int]]:
    if admin.admin:
        return await PaymentStatus.count(
            room,
            paid=paid,
            created_after=created_after,
            created_before=created_before,
        )

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
