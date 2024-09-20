from __future__ import annotations

from fastapi.testclient import TestClient

from main import app


def test_docs() -> None:
    with TestClient(app) as client:
        response = client.get("/docs")
        assert response.status_code == 200


def test_admin_login_ok() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/admin/login",
            headers={
                "Username": "admin",
                "Password": "NgaiLongGey",
            },
        )
        assert response.status_code == 204


def test_admin_login_incorrect_password() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/admin/login",
            headers={
                "Username": "admin",
                "Password": "password",
            },
        )
        assert response.status_code == 403


def test_admin_login_incorrect_username() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/admin/login",
            headers={
                "Username": "user",
                "Password": "NgaiLongGey",
            },
        )
        assert response.status_code == 403


def test_admin_login_incorrect_username_password() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/admin/login",
            headers={
                "Username": "user",
                "Password": "password",
            },
        )
        assert response.status_code == 403
