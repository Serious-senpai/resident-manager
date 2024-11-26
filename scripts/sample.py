from __future__ import annotations

import asyncio
import random
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

from vn_fullname_generator import generate  # type: ignore


root = Path(__file__).parent.parent.resolve()
sys.path.append(str(root))


from server import Database, hash_password  # noqa


now = datetime.now(timezone.utc)


async def populate_account(index: int) -> None:
    name = generate()
    room = 100 + (index + 1) % 100
    birthday = now - timedelta(days=random.randint(6500, 22000))
    phone = f"09999{index:05}"
    email = f"test{index:05}@example.com"
    username = password = f"test{index:05}"
    async with Database.instance.pool.acquire() as connection:
        await connection.execute(
            """
                EXECUTE Register
                    @Name = ?,
                    @Room = ?,
                    @Birthday = ?,
                    @Phone = ?,
                    @Email = ?,
                    @Username = ?,
                    @HashedPassword = ?
            """,
            name,
            room,
            birthday,
            phone,
            email,
            username,
            hash_password(password),
        )


async def populate_fee(index: int) -> None:
    name = f"Test phí #{index + 1}"
    lower = random.randint(0, 1000)
    upper = lower + random.randint(0, 2000)
    per_area = random.randint(0, 100)
    per_motorbike = random.randint(0, 100)
    per_car = random.randint(0, 100)
    deadline = now + timedelta(days=random.randint(7, 6500))
    description = f"[Index {index}] Test phí thôi, nhìn cái gì?\nXuống dòng nè.\nXuống dòng phát nữa nè.\n"
    flags = 0
    async with Database.instance.pool.acquire() as connection:
        await connection.execute(
            """
                EXECUTE CreateFee
                    @Name = ?,
                    @Lower = ?,
                    @Upper = ?,
                    @PerArea = ?,
                    @PerMotorbike = ?,
                    @PerCar = ?,
                    @Deadline = ?,
                    @Description = ?,
                    @Flags = ?
            """,
            name,
            lower * 100000,
            upper * 100000,
            per_area * 100000,
            per_motorbike * 100000,
            per_car * 100000,
            deadline,
            description,
            flags,
        )


async def main() -> None:
    await Database.instance.prepare()
    tasks = [asyncio.create_task(populate_account(i)) for i in range(10000)]
    tasks.extend(asyncio.create_task(populate_fee(i)) for i in range(10000))
    await asyncio.gather(*tasks)


asyncio.run(main())
