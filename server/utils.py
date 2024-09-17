from __future__ import annotations

import secrets
import string
from datetime import datetime, timedelta, timezone
from typing import ClassVar, Optional

from aiohttp import web

from .config import EPOCH


__all__ = (
    "secure_hex_string",
    "since_epoch",
    "from_epoch",
    "error_message",
    "generate_id",
)


def secure_hex_string(length: int) -> str:
    return "".join(secrets.choice(string.hexdigits) for _ in range(length))


def since_epoch(dt: Optional[datetime] = None) -> timedelta:
    if dt is None:
        dt = datetime.now(timezone.utc)

    return dt - EPOCH


def from_epoch(dt: timedelta) -> datetime:
    return EPOCH + dt


def error_message(message: str, *, status: int) -> web.Response:
    return web.json_response({"error": message}, status=status)


class __IDGenerator:

    since_epoch_last: ClassVar[int] = int(1000 * since_epoch().total_seconds())
    counter: ClassVar[int] = 0

    @classmethod
    def generate_id(cls) -> int:
        now = int(1000 * since_epoch().total_seconds())
        if now > cls.since_epoch_last:
            cls.since_epoch_last = now
            cls.counter = 0
        else:
            cls.counter += 1

        return (now << 14) | cls.counter


generate_id = __IDGenerator.generate_id
