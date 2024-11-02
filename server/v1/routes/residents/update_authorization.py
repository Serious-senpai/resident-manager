from __future__ import annotations

from typing import Annotated, Optional

import pydantic
from fastapi import Depends, Response, status

from ...app import api_v1
from ...models import Resident, Result
from ...utils import check_password


__all__ = ("residents_update_authorization",)


class _Payload(pydantic.BaseModel):
    new_username: Annotated[str, pydantic.Field(description="The new authorization username")]
    old_password: Annotated[str, pydantic.Field(description="The old authorization password")]
    new_password: Annotated[str, pydantic.Field(description="The new authorization password")]


@api_v1.post(
    "/residents/update-authorization",
    name="Residents authorization info update",
    description="Update authorization information of a resident",
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
async def residents_update_authorization(
    resident: Annotated[Result[Optional[Resident]], Depends(Resident.from_token)],
    response: Response,
    payload: _Payload,
) -> Result[Optional[Resident]]:
    if resident.data is None or not check_password(payload.old_password, hashed=resident.data.hashed_password):
        response.status_code = status.HTTP_400_BAD_REQUEST
        return Result(code=402, data=None)

    result = await resident.data.update_authorization(payload.new_username, payload.new_password)
    if result.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST

    return result
