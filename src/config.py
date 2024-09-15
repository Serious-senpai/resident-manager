from __future__ import annotations

import os


__all__ = ("PORT",)


PORT = int(os.environ.get("PORT") or 8000)
