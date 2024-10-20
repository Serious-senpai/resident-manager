from __future__ import annotations

from server import global_app


__all__ = ("app",)


# Expose application to uvicorn
app = global_app
