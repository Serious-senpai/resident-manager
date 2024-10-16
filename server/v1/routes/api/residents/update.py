from __future__ import annotations

from typing import Optional, Union

from fastapi import Response, status

from ....apps import api_v1
from ....models import AuthorizationHeader, PublicInfo, Resident, Result


__all__ = ("residents_update",)


async def _resolve_id(
    *,
    id: int,
    headers: AuthorizationHeader,
) -> Union[int, Result[None]]:
    resident = await Resident.authorize(headers)
    if resident.data is not None:
        if resident.data.id == id:
            return id

        return Result(code=301, data=None)

    auth = await headers.verify_admin()
    if auth is not None:
        return auth

    return id


@api_v1.post(
    "/residents/update",
    name="Residents update",
    description="Update information of a resident",
    tags=["admin", "resident"],
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
async def residents_update(
    headers: AuthorizationHeader,
    response: Response,
    id: int,
    info: PublicInfo,
) -> Result[Optional[Resident]]:
    result_id = await _resolve_id(id=id, headers=headers)
    if isinstance(result_id, Result):
        response.status_code = status.HTTP_400_BAD_REQUEST
        return result_id

    result = await Resident.update(id=result_id, info=info)
    if result.data is None:
        response.status_code = status.HTTP_400_BAD_REQUEST

    return result
