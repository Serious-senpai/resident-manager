from __future__ import annotations

from typing import Annotated, Optional

import pydantic
from fastapi import Depends, Header, Response, status

from ...app import api_v1
from ...models import PersonalInfo, Resident, Result


__all__ = ("residents_update",)


class _Authorization(pydantic.BaseModel):
    """Data model for updated authorization credentials."""

    username: Annotated[
        Optional[str],
        pydantic.Field(description="New username for authorization, leave None to keep the value unchanged"),
    ]
    password: Annotated[
        Optional[str],
        pydantic.Field(description="New password for authorization, leave None to keep the value unchanged"),
    ]


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
    headers: Annotated[_Authorization, Header(description="Authorization headers")]
) -> Result[Optional[Resident]]:
    if resident.data is None or resident.data.id != id:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return Result(code=402, data=None)

    result = await Resident.update(id=id, info=info, username=headers.username, password=headers.password)
    if result.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST

    return result
