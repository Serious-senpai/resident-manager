from __future__ import annotations

import asyncio

import fastapi
try:
    import uvloop  # type: ignore
except ImportError:
    pass
else:
    asyncio.set_event_loop_policy(uvloop.EventLoopPolicy())

from server import authorization_router


app = fastapi.FastAPI()
app.include_router(authorization_router)
