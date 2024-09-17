from __future__ import annotations

import functools
import json
from typing import Any

from .residents import Resident
from .snowflake import Snowflake


__all__ = (
    "JSONEncoder",
    "dumps",
    "dump",
)


class JSONEncoder(json.JSONEncoder):
    def default(self, o: Any) -> Any:
        try:
            return super().default(o)

        except TypeError:
            if isinstance(o, Resident):
                return {
                    "id": o.id,
                    "name": o.name,
                    "room": o.room,
                    "birthday": o.birthday,
                    "phone": o.phone,
                    "email": o.email,
                    "username": o.username,
                }

            if isinstance(o, Snowflake):
                return {
                    "id": o.id,
                }

            raise


dumps = functools.partial(json.dumps, cls=JSONEncoder)
dump = functools.partial(json.dump, cls=JSONEncoder)
