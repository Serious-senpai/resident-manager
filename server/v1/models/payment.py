from __future__ import annotations

from typing import Any, Optional

from .results import Result
from .snowflake import Snowflake
from ...database import Database
from ...utils import generate_id


__all__ = ("Payment",)


class Payment(Snowflake):
    """Represents a payment

    Each object of this class corresponds to a database row.
    """

    room: int
    amount: float
    fee_id: int

    @classmethod
    def from_row(cls, row: Any) -> Payment:
        return cls(
            id=row[0],
            room=row[1],
            amount=row[2] / 100,
            fee_id=row[3],
        )

    @classmethod
    async def create(
        cls,
        *,
        room: int,
        amount: float,
        fee_id: int,
    ) -> Result[Optional[Payment]]:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                        DECLARE
                            @Id BIGINT = ?,
                            @Room SMALLINT = ?,
                            @Amount INT = ?,
                            @FeeId BIGINT = ?;

                        INSERT INTO payments
                        OUTPUT INSERTED.*
                        VALUES (
                            @Id,
                            @Room,
                            @Amount,
                            @FeeId
                        )
                    """,
                    generate_id(),
                    room,
                    int(amount * 100),
                    fee_id,
                )
                row = await cursor.fetchone()
                return Result(data=cls.from_row(row))
