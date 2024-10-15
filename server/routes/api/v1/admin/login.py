from __future__ import annotations

from typing import Optional

from fastapi import Response, status

from .....apps import api_v1
from .....models import AuthorizationHeader, Result


__all__ = ("admin_login",)


@api_v1.post(
    "/admin/login",
    name="Administrators login",
    description="Verify administrator authorization data.",
    tags=["admin"],
    response_model=None,
    responses={
        status.HTTP_204_NO_CONTENT: {
            "description": "Successfully logged in",
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_login(
    headers: AuthorizationHeader,
    response: Response,
) -> Optional[Result[None]]:
    result = await headers.verify_admin()
    if result is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST

    return result
