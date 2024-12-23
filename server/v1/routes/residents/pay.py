from __future__ import annotations

import hashlib
import hmac
import urllib.parse
from datetime import datetime, timedelta, timezone
from typing import Dict, Union

from yarl import URL
from fastapi import HTTPException, Request, status
from fastapi.responses import RedirectResponse

from ...app import api_v1
from ...models import Payment, PaymentStatus
from ....config import SERVER_BASE_URL, VNPAY_SECRET_KEY, VNPAY_TMN_CODE
from ....utils import since_epoch, snowflake_time


__all__ = ("residents_pay",)
_BASE = URL("https://sandbox.vnpayment.vn/paymentv2/vpcpay.html")
_RETURN_URL = SERVER_BASE_URL.with_path("/api/v1/residents/vnpay-return")


def _format_time(time: datetime) -> str:
    return time.strftime("%Y%m%d%H%M%S")


@api_v1.get(
    "/residents/pay",
    name="Fee payment",
    description="Perform a payment for a fee",
    tags=["resident"],
    # include_in_schema=False,
)
async def residents_pay(
    request: Request,
    room: int,
    fee_id: int,
    amount: float,
) -> RedirectResponse:
    date = snowflake_time(fee_id)
    all_status = await PaymentStatus.query(room, created_after=date, created_before=date)
    if all_status.data is None:
        raise HTTPException(status.HTTP_400_BAD_REQUEST)

    for st in all_status.data:
        if st.payment is None and st.fee.id == fee_id:
            break

    else:
        raise HTTPException(status.HTTP_404_NOT_FOUND)

    if amount < st.lower_bound or amount > st.upper_bound:
        raise HTTPException(status.HTTP_400_BAD_REQUEST)

    if amount == 0:
        await Payment.create(room=room, amount=amount, fee_id=fee_id)
        return RedirectResponse("/api/v1/static/payment_success.html?amount=0")

    # Construct VNPay URL
    now = datetime.now(timezone(timedelta(hours=7)))
    expire = now + timedelta(hours=1)

    unique_suffix = int(1000 * since_epoch(now).total_seconds())
    normalized_amount = int(100 * amount)
    params: Dict[str, Union[int, str]] = {
        "vnp_Version": "2.1.0",
        "vnp_Command": "pay",
        "vnp_TmnCode": VNPAY_TMN_CODE,
        "vnp_Amount": normalized_amount,
        "vnp_CreateDate": _format_time(now),
        "vnp_CurrCode": "VND",
        "vnp_IpAddr": request.headers.get("x-client-ip", "0.0.0.0"),  # Azure headers containing client IP address
        "vnp_Locale": "vn",
        "vnp_OrderInfo": f"Thanh toan {room} cho {fee_id}",
        "vnp_OrderType": 250000,  # https://sandbox.vnpayment.vn/apis/docs/loai-hang-hoa/
        "vnp_ReturnUrl": str(_RETURN_URL),
        "vnp_ExpireDate": _format_time(expire),
        "vnp_TxnRef": f"{room}-{fee_id}-{normalized_amount}-{unique_suffix}",
    }
    params = dict(sorted(params.items()))

    data = "&".join(f"{k}={urllib.parse.quote_plus(str(v))}" for k, v in params.items())
    params["vnp_SecureHash"] = hmac.new(
        VNPAY_SECRET_KEY.encode("utf-8"),
        data.encode("utf-8"),
        digestmod=hashlib.sha512,
    ).hexdigest()

    url = _BASE.with_query(params)
    return RedirectResponse(str(url))
