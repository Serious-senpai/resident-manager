from __future__ import annotations

from typing import Annotated, List, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, Resident, Result, Snowflake


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
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    objects: List[Snowflake],
) -> Optional[Result[None]]:
    if admin.admin:
        await Resident.delete_many(objects)
        return None

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
