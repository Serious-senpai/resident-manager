from __future__ import annotations

import hashlib
import hmac
import urllib.parse

from fastapi import HTTPException, Request, status
from fastapi.responses import RedirectResponse

from ...app import api_v1
from ....config import SERVER_BASE_URL, VNPAY_SECRET_KEY, VNPAY_TMN_CODE


__all__ = ("residents_vnpay_return",)
_HTML_URL = SERVER_BASE_URL.with_path("/api/v1/static/payment_success.html")


@api_v1.get(
    "/residents/vnpay-return",
    name="VNPay return URL",
    description="Notify the user of a success operation (no update performed at this route)",
    tags=["resident"],
    include_in_schema=False,
)
async def residents_vnpay_return(request: Request) -> RedirectResponse:
    params = dict(sorted(request.query_params.items()))

    # Validate request parameters
    try:
        vnp_securehash = params.pop("vnp_SecureHash")
        vnp_tmncode = params["vnp_TmnCode"]
    except KeyError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST)

    data = "&".join(f"{k}={urllib.parse.quote_plus(str(v))}" for k, v in params.items())
    expected_checksum = hmac.new(
        VNPAY_SECRET_KEY.encode("utf-8"),
        data.encode("utf-8"),
        digestmod=hashlib.sha512,
    ).hexdigest()
    if VNPAY_TMN_CODE != vnp_tmncode or vnp_securehash != expected_checksum:
        raise HTTPException(status.HTTP_400_BAD_REQUEST)

    try:
        vnp_responsecode = params["vnp_ResponseCode"]
        vnp_txnref = params["vnp_TxnRef"]
    except KeyError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST)

    room, fee_id, normalized_amount, _ = map(int, vnp_txnref.split("-"))

    try:
        vnp_amount = int(params["vnp_Amount"])
    except KeyError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST)

    if vnp_amount != normalized_amount:
        raise HTTPException(status.HTTP_400_BAD_REQUEST)

    if vnp_responsecode in {"00", "07"}:
        return RedirectResponse(str(_HTML_URL.with_query({"amount": int(vnp_amount / 100)})))

    raise HTTPException(status.HTTP_400_BAD_REQUEST)
