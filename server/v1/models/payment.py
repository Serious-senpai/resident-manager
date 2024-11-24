from __future__ import annotations

from pyodbc import Row  # type: ignore

from .snowflake import Snowflake


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
