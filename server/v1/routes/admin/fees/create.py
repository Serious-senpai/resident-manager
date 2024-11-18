from __future__ import annotations

from datetime import date
from typing import Annotated, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, Fee, Result


__all__ = ("admin_fees_create",)


@api_v1.post(
    "/admin/fees/create",
    name="Fee creation",
    description="Create a new fee",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "Successfully created a new fee",
            "model": Result[Fee],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Failed to create a new fee",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_200_OK,
)
async def admin_fees_create(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    name: str,
    lower: float,
    upper: float,
    per_area: float,
    per_motorbike: float,
    per_car: float,
    deadline: date,
    description: str,
    flags: int,
) -> Result[Optional[Fee]]:
    if admin.admin:
        fee = await Fee.create(
            name=name,
            lower=lower,
            upper=upper,
            per_area=per_area,
            per_motorbike=per_motorbike,
            per_car=per_car,
            deadline=deadline,
            description=description,
            flags=flags,
        )

        if fee is None:
            response.status_code = status.HTTP_400_BAD_REQUEST

        return fee

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
