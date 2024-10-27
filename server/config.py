from __future__ import annotations

import os
from datetime import datetime, timezone
from pathlib import Path


__all__ = (
    "CI",
    "ODBC_CONNECTION_STRING",
    "VNPAY_TMN_CODE",
    "VNPAY_SECRET_KEY",
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

EPOCH = datetime(2024, 1, 1, 0, 0, 0, 0, timezone.utc)

SALT_LENGTH = 8
DEFAULT_ADMIN_USERNAME = "admin"
DEFAULT_ADMIN_PASSWORD = "NgaiLongGey"

DB_PAGINATION_QUERY = 50


ROOT = Path(__file__).parent.parent.resolve()
