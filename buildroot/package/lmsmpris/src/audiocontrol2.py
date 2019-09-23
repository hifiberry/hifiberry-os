import signal

import configparser
import logging

from mpris import MPRISController
from metadata import MetadataConsole, MetadataScrobbler
from webserver import AudioControlWebserver

mpris = MPRISController()


def pause_all(signalNumber=None, frame=None):
    """
    Pause all players on SIGUSR1
    """
    if mpris is not None:
        mpris.pause_all()


def print_state(signalNumber=None, frame=None):
    """
    Display state on USR2
    """
    if mpris is not None:
        print("\n" + str(mpris))


def parse_config():
    config = configparser.ConfigParser()
    config.read('/etc/audiocontrol2.conf')

    # Auto pause for mpris players
    auto_pause = config.getboolean('mpris', 'auto_pause',
                                   fallback=False)
    logging.debug("Setting auto_pause for MPRIS players to %s",
                  auto_pause)
    mpris.auto_pause = auto_pause

    # Console metadata logger
    if config.getboolean('metadata', 'logger-console', fallback=False):
        logging.debug("Starting console logger")
        mpris.register_metadata_display(MetadataConsole())

    # Web server
    if config.getboolean('webserver', 'webserver-enable', fallback=False):
        logging.debug("Starting webserver")
        port = config.getint('webserver',
                             'webserver-port',
                             fallback=9001)

        ws = AudioControlWebserver(port=port)
        ws.run_server()
        mpris.register_metadata_display(ws)

    # Scrobbler
    scrobbler_network = config.get("scrobbler", "scrobbler-network",
                                   fallback="lastfm")
    scrobbler_apikey = config.get("scrobbler", "scrobbler-apikey")
    scrobbler_apisecret = config.get("scrobbler", "scrobbler-apisecret")
    scrobbler_username = config.get("scrobbler", "scrobbler-username")
    scrobbler_password = config.get("scrobbler", "scrobbler-password")

    if (scrobbler_apikey is not None) and \
        (scrobbler_apisecret is not None) and \
        (scrobbler_apisecret is not None) and \
            (scrobbler_password is not None):
        try:
            scrobbler = MetadataScrobbler(scrobbler_apikey,
                                          scrobbler_apisecret,
                                          scrobbler_username,
                                          scrobbler_password,
                                          None,
                                          scrobbler_network)
            mpris.register_metadata_display(scrobbler)
            logging.info("Scrobbling to %s", scrobbler_network)
        except Exception as e:
            logging.error(e)


def main():

    parse_config()

    signal.signal(signal.SIGUSR1, pause_all)
    signal.signal(signal.SIGUSR2, print_state)

    # mpris.print_players()
    mpris.main_loop()


main()
