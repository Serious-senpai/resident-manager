from __future__ import annotations

from typing import Annotated

from fastapi import Header, status

from ....apps import api_v1
from ....models import Authorization, PublicInfo, Resident
from ....errors import AuthenticationRequired, UserNotFound
from ....utils import check_password


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
        raise UserNotFound

    if not check_password(headers.decrypt_password(), hashed=resident.hashed_password):
        raise AuthenticationRequired

    return resident.to_public_info()
