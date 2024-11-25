from __future__ import annotations

from datetime import datetime, timezone
from typing import Annotated, List, Optional

from fastapi import Depends, Query, Response, status

from ...app import api_v1
from ...models import Fee, PaymentStatus, Resident, Result
from ....config import EPOCH


__all__ = ("residents_fee",)


@api_v1.get(
    "/residents/fee",
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
async def residents_fee(
    resident: Annotated[Result[Optional[Resident]], Depends(Resident.from_token)],
    response: Response,
    *,
    offset: int = 0,
    created_from: Annotated[
        datetime,
        Query(description="Query fees created from this timestamp"),
    ] = EPOCH,
    created_to: Annotated[
        datetime,
        Query(
            description="Query fees created until this timestamp",
            default_factory=lambda: datetime.now(timezone.utc),
        ),
    ],
) -> Result[Optional[List[PaymentStatus]]]:
    if resident.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return Result(code=402, data=None)

    st = await PaymentStatus.query(
        resident.data.room,
        offset=offset,
        created_from=created_from,
        created_to=created_to,
    )
    return Result(data=st)
