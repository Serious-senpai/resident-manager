from __future__ import annotations

from typing import Annotated

import fastapi

from ...models import Authorization, PersonalInfo, RegisterRequest
from ...routers import authorization_router


@authorization_router.post("/register")
async def register(
    data: PersonalInfo,
    headers: Annotated[Authorization, fastapi.Header()],
) -> RegisterRequest:
    return await RegisterRequest.create(
        name=data.name,
        room=data.room,
        birthday=data.birthday,
        phone=data.phone,
        email=data.email,
        username=headers.username,
        password=headers.password,
    )
