from __future__ import annotations

from typing import Any, Optional

from fastapi import HTTPException, status


__all__ = (
    "ResidentManagerException",
    "BadRequest",
    "UserNotFound",
    "UsernameConflictError",
    "PasswordDecryptionError",
    "AuthenticationRequired",
)


class ResidentManagerException(Exception):
    """Base class for all exceptions from this server"""
    pass


class BadRequest(ResidentManagerException, HTTPException):
    """HTTP 400 Bad Request"""

    def __init__(self, *, detail: Optional[Any] = None) -> None:
        super().__init__(status.HTTP_400_BAD_REQUEST, detail=detail)


class UserNotFound(ResidentManagerException, HTTPException):
    """Exception raised when a user is not found."""

    def __init__(self) -> None:
        super().__init__(status.HTTP_404_NOT_FOUND, detail="Failed to find the specified user.")


class UsernameConflictError(ResidentManagerException, HTTPException):
    """Exception raised when a username is already taken."""

    def __init__(self, username: str) -> None:
        super().__init__(status.HTTP_409_CONFLICT, detail=f"Username \"{username}\" has already been taken.")


class PasswordDecryptionError(ResidentManagerException, HTTPException):
    """Exception raised when the server cannot decrypt the password in the header field."""

    def __init__(self) -> None:
        super().__init__(status.HTTP_401_UNAUTHORIZED, detail="Cannot decrypt authorization header.")


class AuthenticationRequired(ResidentManagerException, HTTPException):
    """Exception raised when the user is not authenticated."""

    def __init__(self) -> None:
        super().__init__(status.HTTP_403_FORBIDDEN, detail="Authentication required.")
