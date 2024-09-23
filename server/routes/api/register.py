from __future__ import annotations

from typing import Annotated

from fastapi import HTTPException, Header, status

from ...errors import UserInputError, UsernameConflictError
from ...models import Authorization, PersonalInfo, PublicInfo, RegisterRequest
from ...routers import api_router


@api_router.post(
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
    try:
        request = await RegisterRequest.create(
            name=data.name,
            room=data.room,
            birthday=data.birthday,
            phone=data.phone,
            email=data.email,
            username=headers.username,
            password=headers.password,
        )

    except UsernameConflictError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already taken",
        )

    except UserInputError:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid input",
        )

    return request.to_public_info()
