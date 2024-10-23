from __future__ import annotations

import random
import string
from datetime import datetime, timezone
from typing import Any, Generator, Optional

import pytest
from fastapi import status
from fastapi.testclient import TestClient

from ..app import api_v1
from server import DEFAULT_ADMIN_PASSWORD, check_password


__all__ = ()


@pytest.fixture
def client() -> Generator[TestClient]:
    with TestClient(api_v1) as _client:
        yield _client


def random_string(length: int) -> str:
    return "".join(random.choices(string.ascii_letters, k=length))


def random_numstring(length: int) -> str:
    return "".join(random.choices(string.digits, k=length))


def check_no_registration_request(id: int, *, client: TestClient, admin_token: str) -> None:
    response = client.get(
        "/admin/registration-requests",
        params={"id": id},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["code"] == 0
    assert len(data["data"]) == 0


def check_no_resident(id: int, *, client: TestClient, admin_token: str) -> None:
    response = client.get(
        "/admin/residents",
        params={"id": id},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["code"] == 0
    assert len(data["data"]) == 0


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


def _get_token(
    endpoint: str,
    *,
    client: TestClient,
    username: str,
    password: str,
    status_code: int = status.HTTP_200_OK,
) -> Optional[str]:
    response = client.post(
        endpoint,
        data={"username": username, "password": password},
    )

    assert response.status_code == status_code

    if status_code == status.HTTP_200_OK:
        data = response.json()
        assert data["token_type"] == "bearer"
        return data["access_token"]

    return None


def get_admin_token(client: TestClient, *, username: str, password: str, status_code: int = status.HTTP_200_OK) -> Optional[str]:
    return _get_token("/admin/login", client=client, username=username, password=password, status_code=status_code)


def get_token(client: TestClient, *, username: str, password: str, status_code: int = status.HTTP_200_OK) -> Optional[str]:
    return _get_token("/login", client=client, username=username, password=password, status_code=status_code)


def test_root(client: TestClient) -> None:
    response = client.get("/")
    assert response.status_code == status.HTTP_200_OK


def test_docs(client: TestClient) -> None:
    response = client.get("/docs")
    assert response.status_code == status.HTTP_200_OK


def test_redoc(client: TestClient) -> None:
    response = client.get("/redoc")
    assert response.status_code == status.HTTP_200_OK


admin_usernames = ["admin", random_string(50)]
admin_passwords = [DEFAULT_ADMIN_PASSWORD, random_string(50)]


@pytest.mark.parametrize("username_i", range(len(admin_usernames)))
@pytest.mark.parametrize("password_i", range(len(admin_passwords)))
def test_admin_login(client: TestClient, username_i: int, password_i: int) -> None:
    get_admin_token(
        client,
        username=admin_usernames[username_i],
        password=admin_passwords[password_i],
        status_code=status.HTTP_200_OK if username_i == 0 and password_i == 0 else status.HTTP_400_BAD_REQUEST,
    )


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
        "/register",
        params={
            "name": name,
            "room": room,
            "birthday": birthday.isoformat(),
            "phone": phone,
            "email": email,
        },
        headers=dict(username=username, password=password),
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()
    assert data["code"] == 0
    assert_match(data["data"], name=name, room=room, birthday=birthday, phone=phone, email=email)

    request_id = data["data"]["id"]

    admin_token = get_admin_token(
        client,
        username="admin",
        password=DEFAULT_ADMIN_PASSWORD,
    )
    assert admin_token is not None

    response = client.get(
        "/admin/registration-requests",
        params={"offset": 0, "id": request_id},
        headers={"Authorization": f"Bearer {admin_token}"},
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
        "/admin/registration-requests/accept",
        json=[data[0]],
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == status.HTTP_204_NO_CONTENT

    check_no_registration_request(request_id, client=client, admin_token=admin_token)

    resident_token = get_token(client, username=username, password=password)
    assert resident_token is not None

    response = client.get(
        "/residents/me",
        headers={"Authorization": f"Bearer {resident_token}"},
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

    resident_id = data["id"]

    response = client.post(
        "/admin/residents/delete",
        json=[data],
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == status.HTTP_204_NO_CONTENT

    check_no_resident(resident_id, client=client, admin_token=admin_token)


resident_names = [f"test-{random_string(random.randint(1, 69))}", "", f"test-{random_string(random.randint(256, 10 ** 4 + 7))}"]
resident_rooms = [random.randint(0, 32767), random.randint(-10 ** 9 - 7, -1), random.randint(32768, 10 ** 9 + 7)]
resident_phones = [random_numstring(random.randint(1, 15)), random_numstring(random.randint(16, 10 ** 4 + 7)), random_string(random.randint(1, 10 ** 4 + 7))]
resident_emails = [f"{random_string(random.randint(1, 69))}@{random_string(random.randint(1, 69))}.com", random_string(random.randint(1, 10 ** 4 + 7))]
resident_usernames = [random_string(random.randint(1, 255)), "", random_string(random.randint(256, 10 ** 4 + 7))]
resident_passwords = [random_string(random.randint(8, 255)), random_string(random.randint(1, 7)), random_string(random.randint(256, 10 ** 4 + 7))]


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
        "/register",
        params={
            "name": resident_names[name_i],
            "room": resident_rooms[room_i],
            "birthday": birthday.isoformat(),
            "phone": resident_phones[phone_i],
            "email": resident_emails[email_i],
        },
        headers=dict(username=resident_usernames[username_i], password=resident_passwords[password_i]),
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

    admin_token = get_admin_token(
        client,
        username="admin",
        password=DEFAULT_ADMIN_PASSWORD,
    )
    assert admin_token is not None

    response = client.get(
        "/admin/registration-requests",
        params={"offset": 0, "username": resident_usernames[username_i], "room": resident_rooms[room_i]},
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == status.HTTP_200_OK
    data = response.json()

    assert data["code"] == 0
    assert len(data["data"]) == 0

    assert get_token(
        client,
        username=resident_usernames[username_i],
        password=resident_passwords[password_i],
        status_code=status.HTTP_400_BAD_REQUEST,
    ) is None


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
        "/register",
        params={
            "name": name,
            "room": room,
            "birthday": birthday.isoformat(),
            "phone": phone,
            "email": email,
        },
        headers=dict(username=username, password=password),
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.json()
    assert data["code"] == 106

    password = random_string(random.randint(8, 255))

    response = client.post(
        "/register",
        params={
            "name": name,
            "room": room,
            "birthday": birthday.isoformat(),
            "phone": phone,
            "email": email,
        },
        headers=dict(username=username, password=password),
    )
    assert response.status_code == status.HTTP_200_OK

    data = response.json()
    assert data["code"] == 0
    request_id = data["data"]["id"]

    name = f"test-{random_string(random.randint(1, 69))}"
    room = random.randint(0, 32767)
    birthday = datetime(now.year - 18, now.month, now.day, tzinfo=timezone.utc)
    phone = random_numstring(random.randint(1, 15))
    email = f"{random_string(random.randint(1, 69))}@{random_string(random.randint(1, 69))}.com"
    password = random_string(random.randint(8, 255))

    response = client.post(
        "/register",
        params={
            "name": name,
            "room": room,
            "birthday": birthday.isoformat(),
            "phone": phone,
            "email": email,
        },
        headers=dict(username=username, password=password),
    )
    assert response.status_code == status.HTTP_400_BAD_REQUEST
    data = response.json()
    assert data["code"] == 107

    admin_token = get_admin_token(
        client,
        username="admin",
        password=DEFAULT_ADMIN_PASSWORD,
    )
    assert admin_token is not None

    response = client.post(
        "/admin/registration-requests/reject",
        json=[{"id": request_id}],
        headers={"Authorization": f"Bearer {admin_token}"},
    )
    assert response.status_code == status.HTTP_204_NO_CONTENT

    check_no_registration_request(request_id, client=client, admin_token=admin_token)
