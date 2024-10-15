from __future__ import annotations

from typing import List, Optional

from fastapi import Response, status

from ......apps import api_v1
from ......models import AuthorizationHeader, RegisterRequest, Result, Snowflake


__all__ = ("admin_reg_request_accept",)


@api_v1.post(
    "/admin/reg-request/accept",
    name="Registration requests approval",
    description="Approve one or more registration requests",
    tags=["admin"],
    response_model=None,
    responses={
        status.HTTP_204_NO_CONTENT: {
            "description": "Operation completed successfully",
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_reg_request_accept(
    headers: AuthorizationHeader,
    response: Response,
    objects: List[Snowflake],
) -> Optional[Result[None]]:
    auth = await headers.verify_admin()
    if auth is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return auth

    await RegisterRequest.accept_many(objects)
    return None
