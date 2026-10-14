"""Sliding-window rate limiter, used to protect the AI quota."""

from __future__ import annotations

import time
from collections import deque
from typing import Callable


class SlidingWindowRateLimiter:
    def __init__(
        self,
        *,
        maximum_requests: int,
        window_seconds: float,
        clock: Callable[[], float] = time.monotonic,
    ) -> None:
        if maximum_requests <= 0:
            raise ValueError("maximum_requests must be greater than zero.")

        if window_seconds <= 0:
            raise ValueError("window_seconds must be greater than zero.")

        self._maximum_requests = maximum_requests
        self._window_seconds = window_seconds
        self._clock = clock
        self._request_times_by_key: dict[str, deque[float]] = {}

    def _remove_old_requests(self, key: str, now: float) -> deque[float]:
        request_times = self._request_times_by_key.setdefault(key, deque())

        while request_times and now - request_times[0] >= self._window_seconds:
            request_times.popleft()

        return request_times

    def try_acquire(self, key: str) -> bool:
        """Return True and count the request if the key is under its limit."""
        now = self._clock()
        request_times = self._remove_old_requests(key, now)

        if len(request_times) >= self._maximum_requests:
            return False

        request_times.append(now)
        return True

    def seconds_until_available(self, key: str) -> int:
        """Tell the caller how long to wait (rounded up, at least 1 second)."""
        now = self._clock()
        request_times = self._remove_old_requests(key, now)

        if len(request_times) < self._maximum_requests:
            return 0

        wait_seconds = self._window_seconds - (now - request_times[0])
        return max(1, int(wait_seconds) + 1)

    def forget_idle_keys(self) -> None:
        """Free memory: remove keys that have no recent request."""
        now = self._clock()

        for key in list(self._request_times_by_key):
            if not self._remove_old_requests(key, now):
                del self._request_times_by_key[key]
