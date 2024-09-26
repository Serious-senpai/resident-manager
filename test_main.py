from __future__ import annotations

import random
import string
from datetime import datetime, timezone
from typing import Any

from fastapi import status
from fastapi.testclient import TestClient

from main import app
from server import DEFAULT_ADMIN_PASSWORD


def random_string(length: int) -> str:
    return "".join(random.choices(string.ascii_letters, k=length))


def assert_match(
    data: Any,
    *,
    name: str,
    room: int,
    birthday: datetime,
    phone: str,
    email: str,
) -> None:
    assert name == data["name"]
    assert room == data["room"]

    _birthday = datetime.fromisoformat(data["birthday"])
    assert birthday.year == _birthday.year
    assert birthday.month == _birthday.month
    assert birthday.day == _birthday.day

    assert phone == data["phone"]
    assert email == data["email"]


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


def test_register_main_flow() -> None:
    name = f"test-{random_string(12)}"
    room = random.randint(0, 32767)

    now = datetime.now(timezone.utc)
    birthday = datetime(now.year - 18, now.month, now.day, tzinfo=timezone.utc)

    phone = "0912345678"
    email = f"{name}@example.com"
    username = random_string(12)
    password = random_string(12)

    with TestClient(app) as client:
        response = client.post(
            "/api/register",
            json={
                "name": name,
                "room": room,
                "birthday": birthday.isoformat(),
                "phone": phone,
                "email": email,
            },
            headers={
                "Username": username,
                "Password": password,
            },
        )
        assert response.status_code == status.HTTP_200_OK

        response = client.get(
            "/api/admin/reg-request",
            params={"offset": 0, "name": name},
            headers={
                "Username": "admin",
                "Password": DEFAULT_ADMIN_PASSWORD,
            },
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert len(data) == 1
        assert_match(data[0], name=name, room=room, birthday=birthday, phone=phone, email=email)

        response = client.post(
            "/api/admin/reg-request/accept",
            json=[data[0]["id"]],
            headers={
                "Username": "admin",
                "Password": DEFAULT_ADMIN_PASSWORD,
            },
        )
        assert response.status_code == status.HTTP_204_NO_CONTENT

        response = client.post(
            "/api/login",
            headers={
                "Username": username,
                "Password": password,
            },
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert_match(data, name=name, room=room, birthday=birthday, phone=phone, email=email)

        response = client.post(
            "/api/admin/delete",
            json=[data["id"]],
            headers={
                "Username": "admin",
                "Password": DEFAULT_ADMIN_PASSWORD,
            },
        )
        assert response.status_code == status.HTTP_204_NO_CONTENT
