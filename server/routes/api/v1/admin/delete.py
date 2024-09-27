from __future__ import annotations

from typing import Annotated, List

from fastapi import Header, status

from .....apps import api_v1
from .....database import Database
from .....models import Authorization, Resident


@api_v1.post(
    "/admin/delete",
    name="Account deletion",
    description="Delete one or more resident accounts",
    tags=["admin"],
    response_model=None,
    responses={status.HTTP_401_UNAUTHORIZED: {}, status.HTTP_403_FORBIDDEN: {}},
    status_code=status.HTTP_204_NO_CONTENT,
)
async def admin_delete(ids: List[int], headers: Annotated[Authorization, Header()]) -> None:
    await Database.instance.verify_admin(headers.username, headers.decrypt_password())
    await Resident.delete_many(ids)
