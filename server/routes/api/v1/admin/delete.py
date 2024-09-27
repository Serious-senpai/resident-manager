from __future__ import annotations

from typing import Annotated, List

from fastapi import HTTPException, Header, status

from .....apps import api_v1
from .....database import Database
from .....models import Authorization, Resident


__success_status = status.HTTP_204_NO_CONTENT
__failure_status = status.HTTP_403_FORBIDDEN


@api_v1.post(
    "/admin/delete",
    name="Account deletion",
    description="Delete one or more resident accounts",
    tags=["admin"],
    response_model=None,
    responses={__failure_status: {}},
    status_code=__success_status,
)
async def admin_delete(ids: List[int], headers: Annotated[Authorization, Header()]) -> None:
    if not await Database.instance.verify_admin(headers.username, headers.password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    await Resident.delete_many(ids)
