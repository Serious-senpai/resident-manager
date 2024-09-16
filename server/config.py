from __future__ import annotations

import os


__all__ = ("PORT", "ODBC_CONNECTION_STRING")


PORT = int(os.environ.get("PORT") or 8000)
ODBC_CONNECTION_STRING = os.environ["ODBC_CONNECTION_STRING"]
VNPAY_TMN_CODE = os.environ["VNPAY_TMN_CODE"]
VNPAY_SECRET_KEY = os.environ["VNPAY_SECRET_KEY"]
