class ResidentManagerException(Exception):
    """Base class for all exceptions from this server"""
    pass


class UserInputError(ResidentManagerException):
    """Base exception type for errors that involve errors regarding user input."""
    pass


class UsernameConflictError(UserInputError):
    """Exception raised when a username is already taken."""
    pass
