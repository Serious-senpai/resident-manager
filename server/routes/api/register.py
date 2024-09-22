from __future__ import annotations

from typing import Annotated

from fastapi import HTTPException, Header, status

from ...models import Authorization, PersonalInfo, PublicInfo, RegisterRequest
from ...routers import api_router


@api_router.post(
    "/register",
    name="Residents registration",
    description="Register a resident account to be created.",
    tags=["resident"],
    responses={status.HTTP_400_BAD_REQUEST: {}},
    status_code=status.HTTP_200_OK,
)
async def register(
    data: PersonalInfo,
    headers: Annotated[Authorization, Header()],
) -> PublicInfo:
    request = await RegisterRequest.create(
        name=data.name,
        room=data.room,
        birthday=data.birthday,
        phone=data.phone,
        email=data.email,
        username=headers.username,
        password=headers.password,
    )

    if request is None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to create registration request",
        )

    return request.to_public_info()
