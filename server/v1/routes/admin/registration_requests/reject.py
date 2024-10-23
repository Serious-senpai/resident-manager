from __future__ import annotations

from typing import Annotated, List, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, RegisterRequest, Result, Snowflake


__all__ = ("admin_reg_request_reject",)


@api_v1.post(
    "/admin/registration-requests/reject",
    name="Registration requests rejection",
    description="Reject one or more registration requests",
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
async def admin_reg_request_reject(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    objects: List[Snowflake],
) -> Optional[Result[None]]:
    if admin.admin:
        await RegisterRequest.reject_many(objects)
        return None

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
