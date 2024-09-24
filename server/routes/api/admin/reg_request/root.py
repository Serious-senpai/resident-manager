from __future__ import annotations

from typing import Annotated, List, Optional

from fastapi import HTTPException, Header, status

from .....config import DB_PAGINATION_QUERY
from .....database import Database
from .....models import Authorization, RegisterRequest
from .....routers import api_router


@api_router.get(
    "/admin/reg-request",
    name="Registration requests query",
    description=f"Query a maximum of {DB_PAGINATION_QUERY} registration requests from the specified offset",
    tags=["admin"],
    responses={status.HTTP_401_UNAUTHORIZED: {}},
    status_code=status.HTTP_200_OK,
)
async def admin_reg_request(
    offset: int,
    headers: Annotated[Authorization, Header()],
    name: Optional[str] = None,
    room: Optional[int] = None,
) -> List[RegisterRequest]:
    if not await Database.instance.verify_admin(headers.username, headers.password):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED)

    return await RegisterRequest.query(offset=offset, name=name, room=room)
