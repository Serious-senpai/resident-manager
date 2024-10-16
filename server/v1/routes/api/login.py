from __future__ import annotations

from typing import Optional, cast

from fastapi import Response, status

from ...apps import api_v1
from ...models import AuthorizationHeader, PublicInfo, Resident, Result


__all__ = ("login",)


@api_v1.post(
    "/login",
    name="Residents login",
    description="Verify authorization data, return resident information on success.",
    tags=["resident"],
    responses={
        status.HTTP_200_OK: {
            "description": "Successfully logged in",
            "model": Result[PublicInfo],
        },
        status.HTTP_400_BAD_REQUEST: {
            "description": "Incorrect authorization data",
            "model": Result[None],
        },
    },
)
async def login(
    headers: AuthorizationHeader,
    response: Response,
) -> Result[Optional[PublicInfo]]:
    result = await Resident.authorize(headers)

    if result.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST
        return cast(Result[None], result)

    return Result(data=result.data.to_public_info())
