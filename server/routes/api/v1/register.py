from __future__ import annotations

from typing import Annotated, Optional, cast

from fastapi import Query, Response, status

from ....apps import api_v1
from ....models import (
    AuthorizationHeader,
    PersonalInfo,
    PublicInfo,
    RegisterRequest,
    Result,
)


__all__ = ("register",)


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
    headers: AuthorizationHeader,
    response: Response,
    data: Annotated[PersonalInfo, Query()],
) -> Result[Optional[PublicInfo]]:
    password = headers.decrypt_password()
    if password.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return cast(Result[None], password)

    result = await RegisterRequest.create(
        name=data.name,
        room=data.room,
        birthday=data.birthday,
        phone=data.phone,
        email=data.email,
        username=headers.username,
        password=password.data,
    )

    if result.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return cast(Result[None], result)

    return Result(data=result.data.to_public_info())
