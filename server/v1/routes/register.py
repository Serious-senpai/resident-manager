from __future__ import annotations

from typing import Annotated, Optional

import pydantic
from fastapi import Header, Query, Response, status

from ..app import api_v1
from ..models import (
    PersonalInfo,
    PublicInfo,
    RegisterRequest,
    Result,
)


__all__ = ("register",)


class _Authorization(pydantic.BaseModel):
    """Data model for authorization headers when registering a new account.

    This should only be used to handle registration requests.
    """

    username: Annotated[str, pydantic.Field(description="The username for authorization")]
    password: Annotated[str, pydantic.Field(description="The password for authorization")]


_AuthorizationHeader = Annotated[_Authorization, Header(description="Authorization headers")]


@api_v1.post(
    "/register",
    name="Residents registration",
    description="Register a resident account to be created.",
    tags=["resident"],
    responses={
        status.HTTP_200_OK: {
            "description": "Successfully created a registration request",
            "model": Result[PublicInfo],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Failed to create a registration request",
            "model": Result[None],
        },
    },
)
async def register(
    headers: _AuthorizationHeader,
    response: Response,
    data: Annotated[PersonalInfo, Query()],
) -> Result[Optional[PublicInfo]]:
    result = await RegisterRequest.create(
        name=data.name,
        room=data.room,
        birthday=data.birthday,
        phone=data.phone,
        email=data.email,
        username=headers.username,
        password=headers.password,
    )

    if result.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return result

    return Result(data=result.data.to_public_info())
