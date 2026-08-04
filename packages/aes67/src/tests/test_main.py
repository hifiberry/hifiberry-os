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
