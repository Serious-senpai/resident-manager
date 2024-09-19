from __future__ import annotations

from typing import Annotated

import fastapi
from fastapi import status

from ...models import Authorization, Resident
from ...routers import api_router
from ...utils import check_password


# Not much we can do: https://stackoverflow.com/a/7562744
@api_router.post("/login", name="Residents login", tags=["authorization", "resident"])
async def login(headers: Annotated[Authorization, fastapi.Header()]) -> Resident:
    """Verify authorization data, return resident information on success."""
    resident = await Resident.from_username(headers.username)
    if resident is None:
        raise fastapi.HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"No resident with username \"{headers.username}\"",
        )

    if not check_password(headers.password, hashed=resident.hashed_password):
        raise fastapi.HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Incorrect password",
        )

    return resident
