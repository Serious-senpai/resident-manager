from __future__ import annotations

from typing import List, Tuple

from pyodbc import Row  # type: ignore

from .fee import Fee
from .rooms import RoomData
from .snowflake import Snowflake
from ...database import Database


__all__ = ("Payment",)


class Payment(Snowflake):
    """Represents a payment

    Each object of this class corresponds to a database row.
    """

    room: int
    amount: float
    fee_id: int

    @classmethod
    def from_row(cls, row: Row) -> Payment:
        return cls(
            id=row.id,
            room=row.room,
            amount=row.amount / 100,
            fee_id=row.fee_id,
        )

    @classmethod
    async def query_unpaid(cls, *, room: int) -> List[Tuple[RoomData, Fee]]:
        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                        DECLARE @Room SMALLINT = ?

                        SELECT rooms.*, fee.* FROM fee
                        INNER JOIN rooms ON rooms.room = @Room
                        WHERE fee.id NOT IN (
                            SELECT fee_id FROM payments
                            WHERE room = @Room
                        )
                    """,
                    room,
                )

                rows = await cursor.fetchall()
                return [(RoomData.from_row(row), Fee.from_row(row)) for row in rows]
