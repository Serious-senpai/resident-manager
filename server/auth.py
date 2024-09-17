from __future__ import annotations

from hashlib import sha256
from typing import Optional

from .config import SALT_LENGTH
from .utils import secure_hex_string


__all__ = (
    "hash_password",
    "check_password",
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
