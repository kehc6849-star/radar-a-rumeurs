"""Small in-memory cache so the same message does not use the AI quota twice.

Privacy: the key is a hash of the message, and only the verdict is kept.
The message text itself is never stored.
"""

from __future__ import annotations

import hashlib
import time
from collections import OrderedDict
from typing import Callable, Generic, TypeVar

StoredValue = TypeVar("StoredValue")


def compute_text_cache_key(message_text: str) -> str:
    # Same message with other spaces or capital letters gives the same key.
    normalized_text = " ".join(message_text.lower().split())
    return hashlib.sha256(normalized_text.encode("utf-8")).hexdigest()


class ExpiringCache(Generic[StoredValue]):
    def __init__(
        self,
        *,
        maximum_entries: int,
        time_to_live_seconds: float,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        if maximum_entries <= 0:
            raise ValueError("maximum_entries must be greater than zero.")

        if time_to_live_seconds <= 0:
            raise ValueError("time_to_live_seconds must be greater than zero.")

        self._maximum_entries = maximum_entries
        self._time_to_live_seconds = time_to_live_seconds
        self._clock = clock
        self._entries: OrderedDict[str, tuple[float, StoredValue]] = OrderedDict()

    def get(self, key: str) -> StoredValue | None:
        entry = self._entries.get(key)

        if entry is None:
            return None

        expiration_time, value = entry

        if self._clock() >= expiration_time:
            del self._entries[key]
            return None

        # Recently used entries are kept longest.
        self._entries.move_to_end(key)
        return value

    def put(self, key: str, value: StoredValue) -> None:
        self._entries[key] = (self._clock() + self._time_to_live_seconds, value)
        self._entries.move_to_end(key)

        while len(self._entries) > self._maximum_entries:
            self._entries.popitem(last=False)

    def __len__(self) -> int:
        return len(self._entries)
