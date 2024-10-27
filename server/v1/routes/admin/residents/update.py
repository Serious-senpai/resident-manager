from __future__ import annotations

from typing import Annotated, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, PersonalInfo, Resident, Result


__all__ = ("admin_residents_update",)


@api_v1.post(
    "/admin/residents/update",
    name="Residents update",
    description="Update information of a resident",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "The operation completed successfully",
            "model": Result[Resident],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def admin_residents_update(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    id: int,
    info: PersonalInfo,
) -> Result[Optional[Resident]]:
    if admin.admin:
        result = await Resident.update(id=id, info=info, username=None, password=None)
        if result.data is None:
            response.status_code = status.HTTP_400_BAD_REQUEST

        return result

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
