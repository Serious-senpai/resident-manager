from __future__ import annotations

from datetime import datetime
from typing import Annotated, Any, List, Literal, Optional

import pydantic
from pyodbc import Row  # type: ignore

from .fee import Fee
from .payment import Payment
from .results import Result
from .snowflake import Snowflake
from ...config import DB_PAGINATION_QUERY, EPOCH
from ...database import Database


__all__ = ("PaymentStatus",)


class PaymentStatus(pydantic.BaseModel):
    """Data model for objects holding information about a fee associated to a room
    and optionally a payment.
    """
    fee: Annotated[Fee, pydantic.Field(description="The fee associated to the room")]
    lower_bound: Annotated[float, pydantic.Field(description="The lower bound of the fee, in VND")]
    upper_bound: Annotated[float, pydantic.Field(description="The upper bound of the fee, in VND")]
    payment: Annotated[Optional[Payment], pydantic.Field(description="The payment associated to the fee if the room has already paid this fee")]

    @classmethod
    def from_row(cls, row: Row) -> PaymentStatus:
        fee = Fee(
            id=row.fee_id,
            name=row.fee_name,
            lower=row.fee_lower / 100,
            upper=row.fee_upper / 100,
            per_area=row.fee_per_area / 100,
            per_motorbike=row.fee_per_motorbike / 100,
            per_car=row.fee_per_car / 100,
            deadline=row.fee_deadline,
            description=row.fee_description,
            flags=row.fee_flags,
        )
        payment = Payment(
            id=row.payment_id,
            room=row.payment_room,
            amount=row.payment_amount / 100,
            fee_id=row.payment_fee_id,
        )
        return cls(
            fee=fee,
            lower_bound=row.lower_bound / 100,
            upper_bound=row.upper_bound / 100,
            payment=payment,
        )

    @classmethod
    async def query(
        cls,
        room: int,
        *,
        offset: int = 0,
        created_from: datetime,
        created_to: datetime,
    ) -> List[PaymentStatus]:
        created_from = max(created_from, EPOCH)
        created_to = max(created_to, EPOCH)

        async with Database.instance.pool.acquire() as connection:
            async with connection.cursor() as cursor:
                await cursor.execute(
                    """
                        EXECUTE QueryRoomFee
                            @Room = ?,
                            @CreatedFrom = ?,
                            @CreatedTo = ?,
                            @Offset = ?,
                            @FetchNext = ?
                    """,
                    room,
                    created_from,
                    created_to,
                    offset,
                    DB_PAGINATION_QUERY,
                )

                rows = await cursor.fetchall()
                return [PaymentStatus.from_row(row) for row in rows]
