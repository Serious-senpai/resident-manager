from __future__ import annotations

from fastapi import status

from ....apps import api_v1
from ....security import SERVER_PUBLIC_KEY_BASE64


@api_v1.get(
    "/key",
    name="Server public encryption key",
    description="Obtain server public key for encrypting messages using the Curve25519 algorithm.",
    status_code=status.HTTP_200_OK,
)
async def key() -> str:
    return SERVER_PUBLIC_KEY_BASE64
