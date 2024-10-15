from __future__ import annotations

from typing import List, Optional

from fastapi import Response, status

from ......apps import api_v1
from ......models import AuthorizationHeader, Resident, Result, Snowflake


__all__ = ("admin_residents_delete",)


@api_v1.post(
    "/admin/residents/delete",
    name="Account deletion",
    description="Delete one or more resident accounts",
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
async def admin_residents_delete(
    headers: AuthorizationHeader,
    response: Response,
    objects: List[Snowflake],
) -> Optional[Result[None]]:
    auth = await headers.verify_admin()
    if auth is not None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return auth

    await Resident.delete_many(objects)
    return None
