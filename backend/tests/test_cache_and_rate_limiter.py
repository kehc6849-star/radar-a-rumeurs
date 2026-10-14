import unittest

from app.cache import ExpiringCache, compute_text_cache_key
from app.rate_limiter import SlidingWindowRateLimiter


class FakeClock:
    def __init__(self) -> None:
        self.current_time = 1000.0

    def __call__(self) -> float:
        return self.current_time

    def advance(self, seconds: float) -> None:
        self.current_time += seconds


class CacheKeyTest(unittest.TestCase):
    def test_same_message_gives_same_key_whatever_spaces_and_case(self) -> None:
        self.assertEqual(compute_text_cache_key("Bonjour   LE monde"), compute_text_cache_key(" bonjour le MONDE "))

    def test_key_does_not_contain_the_message(self) -> None:
        self.assertNotIn("bonjour", compute_text_cache_key("bonjour"))


class ExpiringCacheTest(unittest.TestCase):
    def test_value_expires(self) -> None:
        clock = FakeClock()
        cache: ExpiringCache[str] = ExpiringCache(maximum_entries=5, time_to_live_seconds=60, clock=clock)

        cache.put("a", "value")
        self.assertEqual(cache.get("a"), "value")

        clock.advance(61)
        self.assertIsNone(cache.get("a"))
        self.assertEqual(len(cache), 0)

    def test_oldest_entry_is_removed_when_full(self) -> None:
        cache: ExpiringCache[int] = ExpiringCache(maximum_entries=2, time_to_live_seconds=60, clock=FakeClock())

        cache.put("a", 1)
        cache.put("b", 2)
        cache.get("a")  # "a" becomes the most recently used
        cache.put("c", 3)

        self.assertEqual(cache.get("a"), 1)
        self.assertIsNone(cache.get("b"))
        self.assertEqual(cache.get("c"), 3)

    def test_invalid_settings_are_rejected(self) -> None:
        with self.assertRaises(ValueError):
            ExpiringCache(maximum_entries=0, time_to_live_seconds=10)

        with self.assertRaises(ValueError):
            ExpiringCache(maximum_entries=1, time_to_live_seconds=0)


class RateLimiterTest(unittest.TestCase):
    def test_limit_is_applied_per_key(self) -> None:
        limiter = SlidingWindowRateLimiter(maximum_requests=2, window_seconds=60, clock=FakeClock())

        self.assertTrue(limiter.try_acquire("phone-1"))
        self.assertTrue(limiter.try_acquire("phone-1"))
        self.assertFalse(limiter.try_acquire("phone-1"))
        self.assertTrue(limiter.try_acquire("phone-2"))

    def test_window_slides(self) -> None:
        clock = FakeClock()
        limiter = SlidingWindowRateLimiter(maximum_requests=1, window_seconds=60, clock=clock)

        self.assertTrue(limiter.try_acquire("k"))
        self.assertFalse(limiter.try_acquire("k"))
        self.assertGreaterEqual(limiter.seconds_until_available("k"), 1)

        clock.advance(61)
        self.assertEqual(limiter.seconds_until_available("k"), 0)
        self.assertTrue(limiter.try_acquire("k"))

    def test_idle_keys_are_forgotten(self) -> None:
        clock = FakeClock()
        limiter = SlidingWindowRateLimiter(maximum_requests=1, window_seconds=10, clock=clock)

        limiter.try_acquire("k")
        clock.advance(11)
        limiter.forget_idle_keys()

        self.assertTrue(limiter.try_acquire("k"))


if __name__ == "__main__":
    unittest.main()
