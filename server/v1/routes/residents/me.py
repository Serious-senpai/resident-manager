from __future__ import annotations

from typing import Annotated, Optional

from fastapi import Depends, Response, status

from ...app import api_v1
from ...models import Resident, Result


__all__ = ("residents_me",)


@api_v1.get(
    "/residents/me",
    name="Resident self-query",
    description="View information of the currently authorized resident",
    tags=["resident"],
    responses={
        status.HTTP_200_OK: {
            "description": "The operation completed successfully",
            "model": Result[Resident],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def residents_me(
    resident: Annotated[Result[Optional[Resident]], Depends(Resident.from_token)],
    response: Response,
) -> Result[Optional[Resident]]:
    if resident.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST

    return resident
