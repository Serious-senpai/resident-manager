from __future__ import annotations

import asyncio
import random
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import List

from vn_fullname_generator import generate  # type: ignore


root = Path(__file__).parent.parent.resolve()
sys.path.append(str(root))


from server import Database, Fee, RegisterRequest, RoomData  # noqa


now = datetime.now(timezone.utc)
to_approve: List[RegisterRequest] = []


async def populate_account(index: int) -> None:
    name = generate()
    room = 100 + index % 100
    birthday = now - timedelta(days=random.randint(6500, 22000))
    phone = f"09999{index:05}"
    email = f"test{index:05}@example.com"
    username = password = f"test{index:05}"

    request = await RegisterRequest.create(
        name=name,
        room=room,
        birthday=birthday,
        phone=phone,
        email=email,
        username=username,
        password=password,
    )
    if index % 3 != 0 and request.data is not None:
        to_approve.append(request.data)


async def populate_room() -> None:
    await RoomData.update_many(
        [
            RoomData(
                room=room,
                area=100 * random.random(),
                motorbike=random.randint(0, 2),
                car=random.randint(0, 2),
            ) for room in range(100, 200)
        ]
    )


async def populate_fee(index: int) -> None:
    name = f"Test phí #{index + 1}"
    lower = random.randint(0, 1000)
    upper = lower + random.randint(0, 2000)
    per_area = random.randint(0, 100)
    per_motorbike = random.randint(0, 100)
    per_car = random.randint(0, 100)
    deadline = now + timedelta(days=random.randint(7, 6500))
    description = f"[Index {index}] Test phí\nXuống dòng 1\nXuống dòng 2\n"
    flags = 0

    await Fee.create(
        name=name,
        lower=lower * 1000,
        upper=upper * 1000,
        per_area=per_area * 1000,
        per_motorbike=per_motorbike * 1000,
        per_car=per_car * 1000,
        deadline=deadline,
        description=description,
        flags=flags,
    )


async def main() -> None:
    await Database.instance.prepare()
    async with Database.instance.pool.acquire() as connection:
        await connection.execute("DELETE FROM payments")
        await connection.execute("DELETE FROM accounts")
        await connection.execute("DELETE FROM rooms")
        await connection.execute("DELETE FROM fee")

    tasks = [asyncio.create_task(populate_account(i)) for i in range(10000)]
    tasks.append(asyncio.create_task(populate_room()))
    tasks.extend(asyncio.create_task(populate_fee(i)) for i in range(10000))
    await asyncio.gather(*tasks)

    await RegisterRequest.accept_many(to_approve)
    await Database.instance.close()


asyncio.run(main())
