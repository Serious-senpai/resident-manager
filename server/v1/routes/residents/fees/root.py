from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated, List, Optional

from fastapi import Depends, Query, Response, status

from ....app import api_v1
from ....models import Fee, PaymentStatus, Resident, Result
from .....config import EPOCH


__all__ = ("residents_fees",)


@api_v1.get(
    "/residents/fees",
    name="Fee query",
    description="Query information about fees related to the current resident",
    tags=["resident"],
    responses={
        status.HTTP_200_OK: {
            "description": "The operation completed successfully",
            "model": Result[List[Fee]],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def residents_fees(
    resident: Annotated[Result[Optional[Resident]], Depends(Resident.from_token)],
    response: Response,
    *,
    offset: Annotated[int, Query(description="Query offset")] = 0,
    paid: Annotated[Optional[bool], Query(description="Whether to query paid or unpaid fees only")] = None,
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
    if resident.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return Result(code=402, data=None)

    return await PaymentStatus.query(
        resident.data.room,
        offset=offset,
        paid=paid,
        created_after=created_after,
        created_before=created_before,
    )
