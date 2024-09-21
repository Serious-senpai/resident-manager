from __future__ import annotations

import os
from datetime import datetime, timezone


__all__ = (
    "ODBC_CONNECTION_STRING",
    "VNPAY_TMN_CODE",
    "VNPAY_SECRET_KEY",
    "EPOCH",
    "SALT_LENGTH",
    "DEFAULT_ADMIN_USERNAME",
    "DEFAULT_ADMIN_HASHED_PASSWORD",
    "DB_PAGINATION_QUERY",
)


ODBC_CONNECTION_STRING = os.environ["ODBC_CONNECTION_STRING"]
VNPAY_TMN_CODE = os.environ["VNPAY_TMN_CODE"]
VNPAY_SECRET_KEY = os.environ["VNPAY_SECRET_KEY"]

EPOCH = datetime(2024, 1, 1, 0, 0, 0, 0, timezone.utc)

SALT_LENGTH = 8  # If this value is changed, update DEFAULT_ADMIN_HASHED_PASSWORD as well.
DEFAULT_ADMIN_USERNAME = "admin"
DEFAULT_ADMIN_HASHED_PASSWORD = "abe8e47898bcd1cdd46751ca4efe6d98787e043d462701044ddccb2bc6cda61b69696969"

DB_PAGINATION_QUERY = 50
