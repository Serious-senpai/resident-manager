from __future__ import annotations

from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm

from ...app import api_v1
from ...models import AdminPermission, Token


__all__ = ("login",)


@api_v1.post(
    "/admin/login",
    name="Administrators login",
    description="Verify administrator authorization data.",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "Successfully logged in",
            "model": Token,
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
        },
    },
)
async def login(form_data: Annotated[OAuth2PasswordRequestForm, Depends()]) -> Token:
    verify = await AdminPermission.verify(username=form_data.username, password=form_data.password)
    if verify:
        return AdminPermission.create_token()

    raise HTTPException(status.HTTP_400_BAD_REQUEST)
