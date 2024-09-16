from __future__ import annotations

import os


__all__ = ("PORT", "ODBC_CONNECTION_STRING")


PORT = int(os.environ.get("PORT") or 8000)
ODBC_CONNECTION_STRING = os.environ["ODBC_CONNECTION_STRING"]
