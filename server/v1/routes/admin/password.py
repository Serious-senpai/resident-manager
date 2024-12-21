from __future__ import annotations

from typing import Annotated, Optional

import pydantic
from fastapi import Response, status

from ...app import api_v1
from ...models import AdminPermission, Result
from ....database import Database
from ....utils import hash_password


__all__ = ("admin_password",)


class _Payload(pydantic.BaseModel):
    username: Annotated[str, pydantic.Field(description="The username of the administrator")]
    old_password: Annotated[str, pydantic.Field(description="The old password of the administrator")]
    new_password: Annotated[str, pydantic.Field(description="The new password of the administrator")]


@api_v1.post(
    "/admin/password",
    name="Administrator password update",
    description="Update the administrator password",
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
async def admin_password(
    response: Response,
    payload: _Payload,
) -> Optional[Result[None]]:
    verify = await AdminPermission.verify(username=payload.username, password=payload.old_password)
    if verify:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    "UPDATE config SET value = ? WHERE name = 'admin_hashed_password'",
                    hash_password(payload.new_password),
                )

        return None

    response.status_code = status.HTTP_400_BAD_REQUEST
    return Result(code=401, data=None)
