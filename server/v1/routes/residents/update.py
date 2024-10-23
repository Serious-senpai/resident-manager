from __future__ import annotations

from typing import Annotated, Optional

from fastapi import Depends, Response, status

from ...app import api_v1
from ...models import PersonalInfo, Resident, Result


__all__ = ("residents_update",)


@api_v1.post(
    "/residents/update",
    name="Residents update",
    description="Update information of a resident",
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
async def residents_update(
    resident: Annotated[Result[Optional[Resident]], Depends(Resident.from_token)],
    response: Response,
    id: int,
    info: PersonalInfo,
) -> Result[Optional[Resident]]:
    if resident.data is None or resident.data.id != id:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return Result(code=402, data=None)

    result = await Resident.update(id=id, info=info)
    if result.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST

    return result
