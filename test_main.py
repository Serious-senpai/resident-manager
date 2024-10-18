from __future__ import annotations

import random
import string
from datetime import datetime, timezone
from typing import Any, Generator, Optional

import pytest
from fastapi import status
from fastapi.testclient import TestClient

from main import app
from server import DEFAULT_ADMIN_PASSWORD, Authorization, check_password


@pytest.fixture
def client() -> Generator[TestClient]:
    with TestClient(app) as _client:
        yield _client


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


def test_root(client: TestClient) -> None:
    response = client.get("/")
    assert response.status_code == status.HTTP_200_OK


def test_docs(client: TestClient) -> None:
    response = client.get("/docs")
    assert response.status_code == status.HTTP_200_OK


admin_usernames = ["admin", random_string(50)]
admin_passwords = [DEFAULT_ADMIN_PASSWORD, random_string(50)]


@pytest.mark.parametrize("username_i", range(len(admin_usernames)))
@pytest.mark.parametrize("password_i", range(len(admin_passwords)))
def test_admin_login(client: TestClient, username_i: int, password_i: int) -> None:
    response = client.post(
        "/api/v1/admin/login",
        headers=Authorization(
            username=admin_usernames[username_i],
            password=admin_passwords[password_i],
        ).model_dump(),
    )

    if username_i == 0 and password_i == 0:
        assert response.status_code == status.HTTP_204_NO_CONTENT
    else:
        assert response.status_code == status.HTTP_400_BAD_REQUEST

        data = response.json()
        assert data["code"] == 203
        assert data["data"] is None


def test_register_main_flow(client: TestClient) -> None:
    name = f"test-{random_string(12)}"
    room = random.randint(0, 32767)

    now = datetime.now(timezone.utc)
    birthday = datetime(now.year - 18, now.month, now.day, tzinfo=timezone.utc)

    phone = "0912345678"
    email = f"{name}@example.com"
    username = random_string(12)
    password = random_string(12)

    response = client.post(
        "/api/v1/register",
        params={
            "name": name,
            "room": room,
            "birthday": birthday.isoformat(),
            "phone": phone,
            "email": email,
        },
        headers=Authorization(username=username, password=password).model_dump(),
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["code"] == 0
    assert_match(data["data"], name=name, room=room, birthday=birthday, phone=phone, email=email)

    request_id = data["data"]["id"]

    response = client.get(
        "/api/v1/admin/reg-request",
        params={"offset": 0, "id": request_id},
        headers=Authorization(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()

    assert data["code"] == 0

    data = data["data"]
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
        headers=Authorization(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
    )
    assert response.status_code == status.HTTP_204_NO_CONTENT

    response = client.post(
        "/api/v1/login",
        headers=Authorization(username=username, password=password).model_dump(),
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()

    assert data["code"] == 0

    data = data["data"]
    assert_match(
        data,
        name=name,
        room=room,
        birthday=birthday,
        phone=phone,
        email=email,
    )

    response = client.post(
        "/api/v1/admin/residents/delete",
        json=[data],
        headers=Authorization(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
    )
    assert response.status_code == status.HTTP_204_NO_CONTENT


resident_names = [f"test-{random_string(random.randint(1, 69))}", "", f"test-{random_string(random.randint(256, 10**4 + 7))}"]
resident_rooms = [random.randint(0, 32767), random.randint(-10**9 - 7, -1), random.randint(32768, 10**9 + 7)]
resident_phones = [random_numstring(random.randint(1, 15)), random_numstring(random.randint(16, 10**4 + 7)), random_string(random.randint(1, 10**4 + 7))]
resident_emails = [f"{random_string(random.randint(1, 69))}@{random_string(random.randint(1, 69))}.com", random_string(random.randint(1, 10**4 + 7))]
resident_usernames = [random_string(random.randint(1, 255)), "", random_string(random.randint(256, 10**4 + 7))]
resident_passwords = [random_string(random.randint(8, 255)), random_string(random.randint(1, 7)), random_string(random.randint(256, 10**4 + 7))]


@pytest.mark.parametrize("name_i", range(len(resident_names)))
@pytest.mark.parametrize("room_i", range(len(resident_rooms)))
@pytest.mark.parametrize("phone_i", range(len(resident_phones)))
@pytest.mark.parametrize("email_i", range(len(resident_emails)))
@pytest.mark.parametrize("username_i", range(len(resident_usernames)))
@pytest.mark.parametrize("password_i", range(len(resident_passwords)))
def test_register_fail(
    client: TestClient,
    name_i: int,
    room_i: int,
    phone_i: int,
    email_i: int,
    username_i: int,
    password_i: int,
) -> None:
    if name_i == 0 or room_i == 0 or phone_i == 0 or email_i == 0 or username_i == 0 or password_i == 0:
        return

    now = datetime.now(timezone.utc)
    birthday = datetime(now.year - 18, now.month, now.day, tzinfo=timezone.utc)

    response = client.post(
        "/api/v1/register",
        params={
            "name": resident_names[name_i],
            "room": resident_rooms[room_i],
            "birthday": birthday.isoformat(),
            "phone": resident_phones[phone_i],
            "email": resident_emails[email_i],
        },
        headers=Authorization(username=resident_usernames[username_i], password=resident_passwords[password_i]).model_dump(),
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.json()

    if name_i != 0:
        assert data["code"] == 101

    elif room_i != 0:
        assert data["code"] == 102

    elif phone_i != 0:
        assert data["code"] == 103

    elif email_i != 0:
        assert data["code"] == 104

    elif username_i != 0:
        assert data["code"] == 105

    elif password_i != 0:
        assert data["code"] == 106

    response = client.get(
        "/api/v1/admin/reg-request",
        params={"offset": 0, "username": resident_usernames[username_i], "room": resident_rooms[room_i]},
        headers=Authorization(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()

    assert data["code"] == 0
    assert len(data["data"]) == 0

    response = client.post(
        "/api/v1/login",
        headers=Authorization(username=resident_usernames[username_i], password=resident_passwords[password_i]).model_dump(),
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.json()
    assert data["code"] == 201


def test_register_username_taken(client: TestClient) -> None:
    name = f"test-{random_string(random.randint(1, 69))}"
    room = random.randint(0, 32767)
    now = datetime.now(timezone.utc)
    birthday = datetime(now.year - 18, now.month, now.day, tzinfo=timezone.utc)
    phone = random_numstring(random.randint(1, 15))
    email = f"{random_string(random.randint(1, 69))}@{random_string(random.randint(1, 69))}.com"
    username = random_string(255)
    password = random_string(random.randint(256, 10 ** 4 + 7))  # Invalid password

    response = client.post(
        "/api/v1/register",
        params={
            "name": name,
            "room": room,
            "birthday": birthday.isoformat(),
            "phone": phone,
            "email": email,
        },
        headers=Authorization(username=username, password=password).model_dump(),
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.json()
    assert data["code"] == 106

    password = random_string(random.randint(8, 255))

    response = client.post(
        "/api/v1/register",
        params={
            "name": name,
            "room": room,
            "birthday": birthday.isoformat(),
            "phone": phone,
            "email": email,
        },
        headers=Authorization(username=username, password=password).model_dump(),
    )
    assert response.status_code == status.HTTP_200_OK

    data = response.json()
    assert data["code"] == 0
    data = data["data"]

    name = f"test-{random_string(random.randint(1, 69))}"
    room = random.randint(0, 32767)
    birthday = datetime(now.year - 18, now.month, now.day, tzinfo=timezone.utc)
    phone = random_numstring(random.randint(1, 15))
    email = f"{random_string(random.randint(1, 69))}@{random_string(random.randint(1, 69))}.com"
    password = random_string(random.randint(8, 255))

    response = client.post(
        "/api/v1/register",
        params={
            "name": name,
            "room": room,
            "birthday": birthday.isoformat(),
            "phone": phone,
            "email": email,
        },
        headers=Authorization(username=username, password=password).model_dump(),
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    d = response.json()
    assert d["code"] == 107

    response = client.post(
        "/api/v1/admin/reg-request/reject",
        json=[{"id": data["id"]}],
        headers=Authorization(username="admin", password=DEFAULT_ADMIN_PASSWORD).model_dump(),
    )
    assert response.status_code == status.HTTP_204_NO_CONTENT
