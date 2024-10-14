from __future__ import annotations

import base64
import os
from datetime import datetime, timezone


__all__ = (
    "CI",
    "ODBC_CONNECTION_STRING",
    "VNPAY_TMN_CODE",
    "VNPAY_SECRET_KEY",
    "PRIVATE_KEY_SEED",
    "EPOCH",
    "SALT_LENGTH",
    "DEFAULT_ADMIN_USERNAME",
    "DEFAULT_ADMIN_PASSWORD",
    "DB_PAGINATION_QUERY",
)


CI = bool("CI" in os.environ)
ODBC_CONNECTION_STRING = os.environ["ODBC_CONNECTION_STRING"]
VNPAY_TMN_CODE = os.environ["VNPAY_TMN_CODE"]
VNPAY_SECRET_KEY = os.environ["VNPAY_SECRET_KEY"]
PRIVATE_KEY_SEED = base64.b64decode(os.environ["PRIVATE_KEY_SEED"])

EPOCH = datetime(2024, 1, 1, 0, 0, 0, 0, timezone.utc)

SALT_LENGTH = 8
DEFAULT_ADMIN_USERNAME = "admin"
DEFAULT_ADMIN_PASSWORD = "NgaiLongGey"

DB_PAGINATION_QUERY = 50
