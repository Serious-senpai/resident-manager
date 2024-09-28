from __future__ import annotations

from nacl.encoding import Base64Encoder
from nacl.public import PrivateKey

from .config import PRIVATE_KEY_SEED


__all__ = (
    "SERVER_SECRET_KEY",
    "SERVER_PUBLIC_KEY",
    "SERVER_PUBLIC_KEY_BASE64",
)


SERVER_SECRET_KEY = PrivateKey.from_seed(PRIVATE_KEY_SEED)
SERVER_PUBLIC_KEY = SERVER_SECRET_KEY.public_key
SERVER_PUBLIC_KEY_BASE64 = SERVER_PUBLIC_KEY.encode(encoder=Base64Encoder).decode()
