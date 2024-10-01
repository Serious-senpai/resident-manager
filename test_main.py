from __future__ import annotations

import itertools
import random
import string
from datetime import datetime, timezone
from typing import Any, Optional

from fastapi import status
from fastapi.testclient import TestClient
from nacl.encoding import Base64Encoder
from nacl.public import Box, PrivateKey, PublicKey

from main import app
from server import DEFAULT_ADMIN_PASSWORD, Authorization, check_password


def random_string(length: int) -> str:
    return "".join(random.choices(string.ascii_letters, k=length))

def random_numstring(length: int) -> str:
    return "".join(random.choices(string.digits, k=length))


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


def test_admin_login_ok() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/admin/login",
            headers=generate_auth_headers(
                username="admin",
                password=DEFAULT_ADMIN_PASSWORD,
            ).model_dump(),
        )
        assert response.status_code == status.HTTP_204_NO_CONTENT


def test_admin_login_incorrect_password() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/admin/login",
            headers=generate_auth_headers(
                username="admin",
                password=random_string(50),
            ).model_dump(),
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN


def test_admin_login_incorrect_username() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/admin/login",
            headers=generate_auth_headers(
                username=random_string(20),
                password=DEFAULT_ADMIN_PASSWORD,
            ).model_dump(),
        )
        assert response.status_code == status.HTTP_403_FORBIDDEN


def test_admin_login_incorrect_username_password() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/admin/login",
            headers=generate_auth_headers(
                username=random_string(20),
                password=random_string(50),
            ).model_dump(),
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

def test_register_incorrect_input() -> None:
    names = [f"test-{random_string(random.randint(1,69))}", "", f"test-{random_string(random.randint(256,10**4+7))}"]
    rooms = [random.randint(0, 32767), random.randint(-10**9-7, -1), random.randint(32768, 10**9+7)]
    now = datetime.now(timezone.utc)
    birthday = datetime(now.year - 18, now.month, now.day, tzinfo=timezone.utc)
    phones = [random_numstring(random.randint(1,15)), random_numstring(random.randint(16,10**4+7)), random_string(random.randint(1,10**4+7))]
    emails = [f"{random_string(random.randint(1,69))}@{random_string(random.randint(1,69))}.com", random_string(random.randint(1,10**4+7))]
    usernames = [random_string(random.randint(1,255)), "", random_string(random.randint(256,10**4+7))]
    passwords = [random_string(random.randint(8,255)), random_string(random.randint(1,7)), random_string(random.randint(256,10**4+7))]
    subtest = 0
    for name, room, phone, email, username, password in itertools.product(names, rooms, phones, emails, usernames, passwords):
        if (subtest>0):
            print(subtest)
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
                assert response.status_code == 400

                response = client.get(
                    "/api/v1/admin/reg-request",
                    params={"offset": 0, "username": username, "room": room},
                    headers=generate_auth_headers(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
                )
                assert response.status_code == status.HTTP_200_OK
                data = response.json()

                assert len(data) == 0

                response = client.post(
                    "/api/v1/login",
                    headers=generate_auth_headers(username=username, password=password).model_dump(),
                )
                assert response.status_code == status.HTTP_404_NOT_FOUND
        subtest+=1