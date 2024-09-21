from __future__ import annotations

from typing import Annotated, List

from fastapi import HTTPException, Header, status

from ....config import DB_PAGINATION_QUERY
from ....database import Database
from ....models import Authorization, RegisterRequest
from ....routers import api_router


@api_router.get(
    "/admin/reg_request",
    name="Query registration requests",
    tags=["admin", "query"],
    responses={status.HTTP_401_UNAUTHORIZED: {}},
    status_code=status.HTTP_200_OK,
)
async def admin_login(offset: int, headers: Annotated[Authorization, Header()]) -> List[RegisterRequest]:
    f"""Query a maximum of {DB_PAGINATION_QUERY} registration requests from the specified offset"""
    if not await Database.instance.verify_admin(headers.username, headers.password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    return await RegisterRequest.query(offset=offset)
