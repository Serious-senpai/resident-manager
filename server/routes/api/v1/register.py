from __future__ import annotations

from typing import Annotated

from fastapi import Header, status

from ....apps import api_v1
from ....models import Authorization, PersonalInfo, PublicInfo, RegisterRequest


@api_v1.post(
    "/register",
    name="Residents registration",
    description="Register a resident account to be created.",
    tags=["resident"],
    responses={status.HTTP_400_BAD_REQUEST: {}, status.HTTP_409_CONFLICT: {}},
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
        password=headers.decrypt_password(),
    )

    return request.to_public_info()
