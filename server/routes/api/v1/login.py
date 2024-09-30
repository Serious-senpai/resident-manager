from __future__ import annotations

from typing import Annotated

from fastapi import Header, status

from ....apps import api_v1
from ....models import Authorization, PublicInfo, Resident
from ....errors import AuthenticationRequired, PasswordDecryptionError, UserNotFound, register_error
from ....utils import check_password


__all__ = ("login",)


@api_v1.post(
    "/login",
    name="Residents login",
    description="Verify authorization data, return resident information on success.",
    tags=["resident"],
    responses=register_error(AuthenticationRequired, PasswordDecryptionError, UserNotFound),
    status_code=status.HTTP_200_OK,
)
async def login(headers: Annotated[Authorization, Header()]) -> PublicInfo:
    residents = await Resident.query(username=headers.username)
    if len(residents) == 0:
        raise UserNotFound

    resident = residents[0]
    if not check_password(headers.decrypt_password(), hashed=resident.hashed_password):
        raise AuthenticationRequired

    return resident.to_public_info()
