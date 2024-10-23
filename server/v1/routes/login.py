from __future__ import annotations

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from ..app import api_v1
from ..models import Resident, Token


__all__ = ("login",)


@api_v1.post(
    "/login",
    name="Residents login",
    description="Verify authorization data, return JWT token on success.",
    tags=["resident"],
    responses={
        status.HTTP_200_OK: {
            "description": "JWT token for authorization",
            "model": Token,
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
        },
    },
)
async def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]) -> Token:
    result = await Resident.create_token(form_data)
    if result is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST)

    return result
