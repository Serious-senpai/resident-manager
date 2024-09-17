from __future__ import annotations

from hashlib import sha256
from typing import Optional

from .utils import secure_hex_string


__all__ = (
    "hash_password",
    "check_password",
)
SALT_LENGTH = 8  # If this value is changed, update the default admin hashed password as well.


def hash_password(password: str, *, salt: Optional[str] = None) -> str:
    if salt is None:
        salt = secure_hex_string(SALT_LENGTH)

    return sha256((password + salt).encode("utf-8")).hexdigest() + salt


def check_password(password: str, *, hashed: str) -> bool:
    salt = hashed[-SALT_LENGTH:]
    return hashed == hash_password(password, salt=salt)
