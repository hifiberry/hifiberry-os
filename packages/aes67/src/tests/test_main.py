import time
import unittest

from hifiberry_aes67 import main


class MainTest(unittest.TestCase):
    def test_parser_accepts_connect(self):
        args = main.build_parser().parse_args(["connect"])
        self.assertEqual(args.action, "connect")

    def test_parser_accepts_select_with_stream(self):
        args = main.build_parser().parse_args(["select", "--stream", "S"])
        self.assertEqual(args.action, "select")
        self.assertEqual(args.stream, "S")

    def test_parser_defaults_api_port_to_1083(self):
        self.assertEqual(main.build_parser().parse_args(["serve"]).port, 1083)

    def test_connect_watch_flag_parses(self):
        self.assertTrue(main.build_parser().parse_args(["connect", "--watch"]).watch)

    def test_connect_without_watch_does_not_loop(self):
        self.assertFalse(main.build_parser().parse_args(["connect"]).watch)

    def test_streams_action_prints_and_returns_zero(self):
        rc = main.dispatch(
            main.build_parser().parse_args(["streams"]),
            deps={"dump": lambda: [], "streams": lambda objs: []},
        )
        self.assertEqual(rc, 0)

    def test_select_action_persists(self):
        written = {}
        rc = main.dispatch(
            main.build_parser().parse_args(["select", "--stream", "S"]),
            deps={"set_selection": lambda name: written.setdefault("n", name)},
        )
        self.assertEqual(rc, 0)
        self.assertEqual(written["n"], "S")

    def test_select_without_stream_clears(self):
        written = {}
        rc = main.dispatch(
            main.build_parser().parse_args(["select"]),
            deps={"set_selection": lambda name: written.setdefault("n", name)},
        )
        self.assertEqual(rc, 0)
        self.assertIsNone(written["n"])


class ServeTest(unittest.TestCase):
    def test_serve_starts_state_reporter_by_default(self):
        started = {}
        main.dispatch(
            main.build_parser().parse_args(["serve"]),
            deps={"serve": lambda port, interface=None: started.setdefault("port", port),
                  "ensure": lambda interface=None: None,
                  "state_run": lambda **kw: started.setdefault("state", kw)},
        )
        self.assertEqual(started["port"], 1083)
        # The reporter runs on a daemon thread; give it a moment to be entered.
        for _ in range(50):
            if "state" in started:
                break
            time.sleep(0.01)
        self.assertIn("state", started)

    def test_serve_can_suppress_state_reporter(self):
        started = {}
        main.dispatch(
            main.build_parser().parse_args(["serve", "--no-state"]),
            deps={"serve": lambda port, interface=None: started.setdefault("port", port),
                  "ensure": lambda interface=None: None,
                  "state_run": lambda **kw: started.setdefault("state", kw)},
        )
        time.sleep(0.05)
        self.assertNotIn("state", started)


class LatencyCliTest(unittest.TestCase):
    def test_set_latency_parses_integer(self):
        seen = {}
        rc = main.dispatch(
            main.build_parser().parse_args(["set-latency", "--latency", "10"]),
            deps={"apply_latency": lambda v, interface=None:
                  seen.setdefault("v", v) or {"latency_msec": v}},
        )
        self.assertEqual(rc, 0)
        self.assertEqual(seen["v"], 10)

    def test_set_latency_default_restores_board_default(self):
        seen = {}
        main.dispatch(
            main.build_parser().parse_args(["set-latency", "--latency", "default"]),
            deps={"apply_latency": lambda v, interface=None:
                  seen.setdefault("v", v) or {"latency_msec": 20}},
        )
        self.assertIsNone(seen["v"])

    def test_settings_action_prints_current(self):
        rc = main.dispatch(
            main.build_parser().parse_args(["settings"]),
            deps={"current": lambda: {"latency_msec": 20}},
        )
        self.assertEqual(rc, 0)

    def test_serve_ensures_config_before_listening(self):
        """The drop-in must match settings before the API answers."""
        order = []
        main.dispatch(
            main.build_parser().parse_args(["serve", "--no-state"]),
            deps={"ensure": lambda interface=None: order.append("ensure"),
                  "serve": lambda port, interface=None: order.append("serve")},
        )
        self.assertEqual(order, ["ensure", "serve"])


class SyncThreadTest(unittest.TestCase):
    def test_serve_starts_the_settings_sync(self):
        started = {}
        main.dispatch(
            main.build_parser().parse_args(["serve", "--no-state"]),
            deps={"ensure": lambda interface=None: None,
                  "seed": lambda: None,
                  "sync_run": lambda **kw: started.setdefault("sync", kw),
                  "serve": lambda port, interface=None: None},
        )
        for _ in range(50):
            if "sync" in started:
                break
            time.sleep(0.01)
        self.assertIn("sync", started)

    def test_serve_seeds_the_board_default_first(self):
        order = []
        main.dispatch(
            main.build_parser().parse_args(["serve", "--no-state"]),
            deps={"seed": lambda: order.append("seed"),
                  "ensure": lambda interface=None: order.append("ensure"),
                  "sync_run": lambda **kw: None,
                  "serve": lambda port, interface=None: order.append("serve")},
        )
        self.assertEqual(order, ["seed", "ensure", "serve"])
