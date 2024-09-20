from __future__ import annotations

from typing import Annotated

from fastapi import Header

from ...models import Authorization, PersonalInfo, RegisterRequest
from ...routers import api_router


@api_router.post("/register", name="Residents register", tags=["authorization", "resident"])
async def register(
    data: PersonalInfo,
    headers: Annotated[Authorization, Header()],
) -> RegisterRequest:
    """Register a resident account to be created."""
    return await RegisterRequest.create(
        name=data.name,
        room=data.room,
        birthday=data.birthday,
        phone=data.phone,
        email=data.email,
        username=headers.username,
        password=headers.password,
    )
