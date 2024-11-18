from __future__ import annotations

import re
import secrets
import string
import struct
from datetime import datetime, timedelta, timezone
from hashlib import sha256
from random import randbytes
from typing import Optional

from .config import EPOCH, SALT_LENGTH


__all__ = (
    "hash_password",
    "check_password",
    "secure_hex_string",
    "since_epoch",
    "from_epoch",
    "snowflake_time",
    "generate_id",
    "validate_name",
    "validate_room",
    "validate_phone",
    "validate_email",
    "validate_username",
    "validate_password",
)


def hash_password(password: str, *, salt: Optional[str] = None) -> str:
    """Hash a password using SHA-256 and a random salt."""
    if salt is None:
        salt = secure_hex_string(SALT_LENGTH)

    return sha256((password + salt).encode("utf-8")).hexdigest() + salt


def check_password(password: str, *, hashed: str) -> bool:
    """Check if a password matches a hashed password."""
    salt = hashed[-SALT_LENGTH:]
    return hashed == hash_password(password, salt=salt)


def secure_hex_string(length: int) -> str:
    """Generate a secure random hexadecimal string."""
    return "".join(secrets.choice(string.hexdigits) for _ in range(length))


def since_epoch(dt: Optional[datetime] = None) -> timedelta:
    """Get the timedelta since the epoch.

    Attributes
    -----
    dt: `Optional[datetime]`
        The datetime to calculate the timedelta from. If not provided, the current time is used.

    Returns
    -----
    `timedelta`
        The timedelta since the epoch: `dt - EPOCH`.
    """
    if dt is None:
        dt = datetime.now(timezone.utc)

    return dt - EPOCH


def from_epoch(dt: timedelta) -> datetime:
    """Calculate the datetime from the timedelta since the epoch."""
    return EPOCH + dt


def snowflake_time(id: int) -> datetime:
    """Get the creation date of a snowflake ID."""
    return from_epoch(timedelta(milliseconds=id >> (8 * 3)))


def generate_id() -> int:
    now = int(1000 * since_epoch().total_seconds())
    tail = struct.unpack("I", randbytes(4))[0] & 0x00FFFFFF
    result = (now << (8 * 3)) | tail
    return result


def validate_name(name: str) -> bool:
    return len(name) > 0 and len(name) < 256


def validate_room(room: int) -> bool:
    return room >= 0 and room < 32768


def validate_phone(phone: str) -> bool:
    return phone.isdigit() and len(phone) < 16


def validate_email(email: str) -> bool:
    return re.fullmatch(r"[\w\.-]+@[\w\.-]+\.[\w\.]+[\w\.]?", email) is not None and len(email) < 256


def validate_username(username: str) -> bool:
    return len(username) > 0 and len(username) < 256


def validate_password(password: str) -> bool:
    return len(password) >= 8 and len(password) < 256


def validate_fee_name(name: str) -> bool:
    return len(name) > 0 and len(name) < 256


def validate_fee_bounds(lower: float, upper: float) -> bool:
    return lower >= 0 and lower < upper and upper <= 21474835


def validate_fee_per_area(value: float) -> bool:
    return -21474835 <= value <= 21474835


def validate_fee_per_motorbike(value: float) -> bool:
    return -21474835 <= value <= 21474835


def validate_fee_per_car(value: float) -> bool:
    return -21474835 <= value <= 21474835
