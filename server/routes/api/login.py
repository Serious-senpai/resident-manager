from __future__ import annotations

from typing import Annotated

import fastapi

from ...auth import check_password
from ...models import Authorization, Resident
from ...routers import authorization_router


# Not much we can do: https://stackoverflow.com/a/7562744
@authorization_router.post("/login")
async def login(headers: Annotated[Authorization, fastapi.Header()]) -> Resident:
    resident = await Resident.from_username(headers.username)
    if resident is None:
        raise fastapi.HTTPException(status_code=403, detail=f"No resident with username \"{headers.username}\"")

    if not check_password(headers.password, hashed=resident.hashed_password):
        raise fastapi.HTTPException(status_code=403, detail="Incorrect password")

    return resident
