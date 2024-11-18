from __future__ import annotations

from typing import Annotated, List, Literal, Optional

from fastapi import Depends, Response, status

from ....app import api_v1
from ....models import AdminPermission, Fee, Result


__all__ = ("admin_fees",)


@api_v1.get(
    "/admin/fees",
    name="Fee query",
    description="Query a list of fees",
    tags=["admin"],
    responses={
        status.HTTP_200_OK: {
            "description": "List of fees",
            "model": Result[List[Fee]],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
    status_code=status.HTTP_200_OK,
)
async def admin_fees(
    admin: Annotated[AdminPermission, Depends(AdminPermission.from_token)],
    response: Response,
    offset: int = 0,
    id: Optional[int] = None,
    name: Optional[str] = None,
    order_by: Literal[
        "id",
        "name",
        "lower",
        "upper",
        "per_area",
        "per_motorbike",
        "per_car",
        "deadline",
    ] = "id",
    ascending: bool = True,
) -> Result[Optional[List[Fee]]]:
    if admin.admin:
        return Result(
            data=await Fee.query(
                offset=offset,
                id=id,
                name=name,
                order_by=order_by,
                ascending=ascending
            )
        )

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
