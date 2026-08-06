import json
import unittest

from hifiberry_aes67 import configdb


class FakeResponse:
    def __init__(self, payload, status=200):
        self._payload = payload
        self.status = status

    def read(self):
        return json.dumps(self._payload).encode()

    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


class ConfigDbTest(unittest.TestCase):
    def test_get_returns_value(self):
        opener = lambda url, timeout=0: FakeResponse(
            {"status": "success", "data": {"key": "k", "value": "10"}})
        self.assertEqual(configdb.get("k", opener=opener), "10")

    def test_get_returns_none_when_key_missing(self):
        def opener(url, timeout=0):
            raise OSError("404")
        self.assertIsNone(configdb.get("k", opener=opener))

    def test_get_returns_none_on_unexpected_payload(self):
        opener = lambda url, timeout=0: FakeResponse({"status": "error"})
        self.assertIsNone(configdb.get("k", opener=opener))

    def test_get_builds_the_expected_url(self):
        seen = {}

        def opener(url, timeout=0):
            seen["url"] = url
            return FakeResponse({"status": "success", "data": {"value": "x"}})

        configdb.get("player.aes67.latency", opener=opener)
        self.assertEqual(
            seen["url"],
            "http://localhost:1081/api/v1/key/player.aes67.latency")

    def test_set_posts_the_value(self):
        seen = {}

        def opener(request, timeout=0):
            seen["url"] = request.full_url
            seen["body"] = json.loads(request.data.decode())
            return FakeResponse({"status": "success", "data": {}})

        self.assertTrue(configdb.set("player.aes67.latency", 20, opener=opener))
        self.assertEqual(seen["body"], {"value": "20"})

    def test_set_returns_false_when_unreachable(self):
        def opener(request, timeout=0):
            raise OSError("refused")
        self.assertFalse(configdb.set("k", "v", opener=opener))

    def test_setting_keys_are_namespaced_by_service(self):
        self.assertEqual(configdb.setting_key("latency"),
                         "player.aes67.latency")
