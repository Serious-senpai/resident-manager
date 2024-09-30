from __future__ import annotations

from typing import Annotated

import pydantic
from fastapi import Header
from nacl.encoding import Base64Encoder
from nacl.public import Box, PublicKey

from ..errors import PasswordDecryptionError
from ..security import SERVER_SECRET_KEY


__all__ = ("Authorization", "AuthorizationHeader", "HashedAuthorization")


class Authorization(pydantic.BaseModel):
    """Data model for authorization headers"""

    username: str
    encrypted: str
    pkey: str

    def decrypt_password(self, *, raise_http_exception: bool = True) -> str:
        try:
            box = Box(SERVER_SECRET_KEY, PublicKey(self.pkey.encode("utf-8"), encoder=Base64Encoder))
            return box.decrypt(self.encrypted.encode("utf-8"), encoder=Base64Encoder).decode("utf-8")

        except BaseException:
            if raise_http_exception:
                raise PasswordDecryptionError

            raise


AuthorizationHeader = Annotated[Authorization, Header(description="Authorization headers")]


class HashedAuthorization(pydantic.BaseModel):
    """Data model for authorization with hashed password.

    Keep in mind that using underscore in headers is not safe.
    """

    username: str
    hashed_password: str
