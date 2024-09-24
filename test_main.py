from __future__ import annotations

from fastapi import status
from fastapi.testclient import TestClient

from main import app
from server import DEFAULT_ADMIN_PASSWORD


def test_docs() -> None:
    with TestClient(app) as client:
        response = client.get("/docs")
        assert response.status_code == status.HTTP_200_OK


def test_admin_login_ok() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/admin/login",
            headers={
                "Username": "admin",
                "Password": DEFAULT_ADMIN_PASSWORD,
            },
        )
        assert response.status_code == status.HTTP_204_NO_CONTENT


def test_admin_login_incorrect_password() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/admin/login",
            headers={
                "Username": "admin",
                "Password": "password",
            },
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN


def test_admin_login_incorrect_username() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/admin/login",
            headers={
                "Username": "user",
                "Password": DEFAULT_ADMIN_PASSWORD,
            },
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN


def test_admin_login_incorrect_username_password() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/admin/login",
            headers={
                "Username": "user",
                "Password": "password",
            },
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN
