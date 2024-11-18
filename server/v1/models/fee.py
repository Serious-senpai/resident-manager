from __future__ import annotations

from datetime import date
from typing import Annotated, Any, List, Literal, Optional

import pydantic

from .results import Result
from .snowflake import Snowflake
from ..database import Database
from ..utils import (
    generate_id,
    validate_fee_bounds,
    validate_fee_name,
    validate_fee_per_area,
    validate_fee_per_car,
    validate_fee_per_motorbike,
)
from ...config import DB_PAGINATION_QUERY


class Fee(Snowflake):
    """Data model for objects holding information about a fee for each room.

    Each object of this class corresponds to a database row.
    """

    name: Annotated[str, pydantic.Field(description="The name of the fee")]
    lower: Annotated[float, pydantic.Field(description="The base lower bound of the fee")]
    upper: Annotated[float, pydantic.Field(description="The base upper bound of the fee")]
    per_area: Annotated[float, pydantic.Field(description="Additional fee per room area (in square meters)")]
    per_motorbike: Annotated[float, pydantic.Field(description="Additional fee per room's motorbike")]
    per_car: Annotated[float, pydantic.Field(description="Additional fee per room's car")]
    deadline: Annotated[date, pydantic.Field(description="The deadline for the fee")]
    description: Annotated[str, pydantic.Field(description="The fee description")]
    flags: Annotated[int, pydantic.Field(description="Bitmask flags of the fee")]

    @classmethod
    def from_row(cls, row: Any) -> Fee:
        """Create a new `Fee` object from a database row.

        Parameters
        -----
        row: `Any`
            The database row.

        Returns
        -----
        `Fee`
            The new `Fee` object.
        """
        return cls(
            id=row[0],
            name=row[1],
            lower=row[2] / 100,
            upper=row[3] / 100,
            per_area=row[4] / 100,
            per_motorbike=row[5] / 100,
            per_car=row[6] / 100,
            deadline=row[7],
            description=row[8],
            flags=row[9],
        )

    @classmethod
    async def create(
        cls,
        *,
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
        if not validate_fee_name(name):
            return Result(code=601, data=None)

        if not validate_fee_bounds(lower, upper):
            return Result(code=602, data=None)

        if not validate_fee_per_area(per_area):
            return Result(code=603, data=None)

        if not validate_fee_per_motorbike(per_motorbike):
            return Result(code=604, data=None)

        if not validate_fee_per_car(per_car):
            return Result(code=605, data=None)

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                print(name, lower, upper, per_area, per_motorbike, per_car, deadline, description, flags)
                await cursor.execute(
                    """
                        DECLARE
                            @Id BIGINT = ?,
                            @Name NVARCHAR(255) = ?,
                            @Lower INT = ?,
                            @Upper INT = ?,
                            @PerArea INT = ?,
                            @PerMotorbike INT = ?,
                            @PerCar INT = ?,
                            @Deadline DATE = ?,
                            @Description NVARCHAR(max) = ?,
                            @Flags TINYINT = ?;

                        INSERT INTO fee
                        OUTPUT INSERTED.*
                        VALUES (@Id, @Name, @Lower, @Upper, @PerArea, @PerMotorbike, @PerCar, @Deadline, @Description, @Flags)
                    """,
                    generate_id(),
                    name,
                    int(lower * 100),
                    int(upper * 100),
                    int(per_area * 100),
                    int(per_motorbike * 100),
                    int(per_car * 100),
                    deadline,
                    description,
                    flags,
                )
                row = await cursor.fetchone()
                return Result(code=0, data=cls.from_row(row))

    @classmethod
    async def query(
        cls,
        *,
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
    ) -> List[Fee]:
        where: List[str] = []
        params: List[Any] = []

        if id is not None:
            where.append("id = ?")
            params.append(id)

        if name is not None:
            if not validate_fee_name(name):
                return []

            where.append("CHARINDEX(?, name) > 0")
            params.append(name)

        query = ["SELECT * FROM fee"]
        if len(where) > 0:
            query.append("WHERE " + " AND ".join(where))

        if order_by not in {
            "id",
            "name",
            "lower",
            "upper",
            "per_area",
            "per_motorbike",
            "per_car",
            "deadline",
        }:
            order_by = "id"

        asc_desc = "ASC" if ascending else "DESC"
        query.append(f"ORDER BY {order_by} {asc_desc} OFFSET ? ROWS FETCH NEXT ? ROWS ONLY")

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute("\n".join(query), *params, offset, DB_PAGINATION_QUERY)

                rows = await cursor.fetchall()
                return [cls.from_row(row) for row in rows]
