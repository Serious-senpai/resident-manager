from __future__ import annotations

from typing import Annotated

from fastapi import HTTPException, Header, status

from ....apps import api_v1
from ....models import Authorization, PublicInfo, Resident
from ....utils import check_password


# Not much we can do: https://stackoverflow.com/a/7562744
@api_v1.post(
    "/login",
    name="Residents login",
    description="Verify authorization data, return resident information on success.",
    tags=["resident"],
    responses={status.HTTP_403_FORBIDDEN: {}},
    status_code=status.HTTP_200_OK,
)
async def login(headers: Annotated[Authorization, Header()]) -> PublicInfo:
    resident = await Resident.from_username(headers.username)
    if resident is None:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"No resident with username \"{headers.username}\"",
        )

    if not check_password(headers.password, hashed=resident.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Incorrect password",
        )

    return resident.to_public_info()
