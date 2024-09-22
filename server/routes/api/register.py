from __future__ import annotations

from typing import Annotated

from fastapi import HTTPException, Header, status

from ...models import Authorization, PersonalInfo, RegisterRequest
from ...routers import api_router


@api_router.post(
    "/register",
    name="Residents register",
    description="Register a resident account to be created.",
    tags=["authorization", "resident"],
    response_model=None,
    responses={status.HTTP_400_BAD_REQUEST: {}},
    status_code=status.HTTP_204_NO_CONTENT,
)
async def register(
    data: PersonalInfo,
    headers: Annotated[Authorization, Header()],
) -> None:
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

    else:
        return None
