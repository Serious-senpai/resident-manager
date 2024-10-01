from __future__ import annotations

import random
import string
from datetime import datetime, timezone
from typing import Any, Optional

import pytest
from fastapi import status
from fastapi.testclient import TestClient
from nacl.encoding import Base64Encoder
from nacl.public import Box, PrivateKey, PublicKey

from main import app
from server import DEFAULT_ADMIN_PASSWORD, Authorization, check_password


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
    username: Optional[str] = None,
    password: Optional[str] = None,
) -> None:
    assert name == data["name"]
    assert room == data["room"]

    _birthday = datetime.fromisoformat(data["birthday"])
    assert birthday.year == _birthday.year
    assert birthday.month == _birthday.month
    assert birthday.day == _birthday.day

    assert phone == data["phone"]
    assert email == data["email"]

    if username is not None:
        assert username == data["username"]

    if password is not None:
        assert check_password(password, hashed=data["hashed_password"])


def generate_auth_headers(*, username: str, password: str) -> Authorization:
    private_key = PrivateKey.generate()
    public_key = private_key.public_key

    server_key = PublicKey(b"FUgK7Fi7O7eSDi5Ekd/hbmjIN3k/WcLevFTgZqmn9Bo=", encoder=Base64Encoder)

    box = Box(private_key, server_key)

    return Authorization(
        username=username,
        encrypted=box.encrypt(password.encode("utf-8"), encoder=Base64Encoder).decode("utf-8"),
        pkey=public_key.encode(encoder=Base64Encoder).decode("utf-8"),
    )


def test_docs() -> None:
    with TestClient(app) as client:
        response = client.get("/docs")
        assert response.status_code == status.HTTP_200_OK


admin_usernames = ["admin", random_string(50)]
admin_passwords = [DEFAULT_ADMIN_PASSWORD, random_string(50)]


@pytest.mark.parametrize("username_i", range(len(admin_usernames)))
@pytest.mark.parametrize("password_i", range(len(admin_passwords)))
def test_admin_login(username_i: int, password_i: int) -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/admin/login",
            headers=generate_auth_headers(
                username=admin_usernames[username_i],
                password=admin_passwords[password_i],
            ).model_dump(),
        )

        if username_i == 0 and password_i == 0:
            assert response.status_code == status.HTTP_204_NO_CONTENT
        else:
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
            "/api/v1/register",
            params={
                "name": name,
                "room": room,
                "birthday": birthday.isoformat(),
                "phone": phone,
                "email": email,
            },
            headers=generate_auth_headers(username=username, password=password).model_dump(),
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert_match(data, name=name, room=room, birthday=birthday, phone=phone, email=email)

        request_id = data["id"]

        response = client.get(
            "/api/v1/admin/reg-request",
            params={"offset": 0, "id": request_id},
            headers=generate_auth_headers(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert len(data) == 1
        assert_match(
            data[0],
            name=name,
            room=room,
            birthday=birthday,
            phone=phone,
            email=email,
            username=username,
            password=password,
        )

        response = client.post(
            "/api/v1/admin/reg-request/accept",
            json=[data[0]],
            headers=generate_auth_headers(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
        )
        assert response.status_code == status.HTTP_204_NO_CONTENT

        response = client.post(
            "/api/v1/login",
            headers=generate_auth_headers(username=username, password=password).model_dump(),
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()

        assert_match(data, name=name, room=room, birthday=birthday, phone=phone, email=email)

        response = client.post(
            "/api/v1/admin/delete",
            json=[data],
            headers=generate_auth_headers(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
        )
        assert response.status_code == status.HTTP_204_NO_CONTENT
