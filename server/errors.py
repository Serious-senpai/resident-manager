from __future__ import annotations

from typing import Any, ClassVar, Dict, Type, Union, TYPE_CHECKING

from fastapi import HTTPException, status


__all__ = (
    "ResidentManagerException",
    "BadRequest",
    "UserNotFound",
    "UsernameConflictError",
    "PasswordDecryptionError",
    "AuthenticationRequired",
    "register_error",
)


class ResidentManagerException(Exception):
    """Base class for all exceptions from this server"""
    pass


class ResidentManagerHTTPException(ResidentManagerException, HTTPException):

    if TYPE_CHECKING:
        status: ClassVar[int]
        message: ClassVar[Any]

    def __init_subclass__(cls, *, status: int, message: Any, **kwargs: Any) -> None:
        super().__init_subclass__(**kwargs)
        cls.status = status
        cls.message = message

    def __init__(self) -> None:
        self.status_code = self.status
        self.detail = self.message


class BadRequest(ResidentManagerHTTPException, status=status.HTTP_400_BAD_REQUEST, message="Bad request"):
    """HTTP 400 Bad Request"""
    pass


class UserNotFound(ResidentManagerHTTPException, status=status.HTTP_404_NOT_FOUND, message="Failed to find the specified user"):
    """Exception raised when a user is not found."""
    pass


class UsernameConflictError(ResidentManagerHTTPException, status=status.HTTP_409_CONFLICT, message="Username has already been taken"):
    """Exception raised when a username is already taken."""
    pass


class PasswordDecryptionError(ResidentManagerHTTPException, status=status.HTTP_401_UNAUTHORIZED, message="Cannot decrypt authorization header"):
    """Exception raised when the server cannot decrypt the password in the header field."""
    pass


class AuthenticationRequired(ResidentManagerHTTPException, status=status.HTTP_403_FORBIDDEN, message="Authentication required"):
    """Exception raised when the user is not authenticated."""
    pass


def register_error(*errors: Type[ResidentManagerHTTPException]) -> Dict[Union[int, str], Dict[str, Any]]:
    """Register error codes for a FastAPI route.

    Args:
        *errors: The errors to register.

    Returns:
        A dictionary with the registered errors.
    """
    return {e.status: {"description": e.message} for e in errors}
