import dbus
import time
import logging

from metadata import Metadata

PLAYING = "playing"

mpris = None

MPRIS_NEXT = "Next"
MPRIS_PREV = "Previous"
MPRIS_PAUSE = "Pause"
MPRIS_PLAYPAUSE = "PlayPause"
MPRIS_STOP = "Stop"
MPRIS_PLAY = "Play"

mpris_commands = [MPRIS_NEXT, MPRIS_PREV,
                  MPRIS_PAUSE, MPRIS_PLAYPAUSE,
                  MPRIS_STOP, MPRIS_PLAY]


def array_to_string(arr):
    """
    Converts an array of objects to a comma separated string
    """
    res = ""
    for part in arr:
        res = res + part + ", "
    if len(res) > 1:
        return res[:-2]
    else:
        return ""


class PlayerState:
    """
    Internal representation of the state of a player
    """

    def __init__(self, state="unknown", metadata=None):
        self.state = state
        if metadata is not None:
            self.metadata = metadata
        else:
            self.metadata = Metadata()

    def __str__(self):
        return self.state + str(self.metadata)


class MPRISController:
    """
    Controller for MPRIS enabled media players
    """

    def __init__(self, auto_pause=True):
        self.state_table = {}
        self.bus = dbus.SystemBus()
        self.auto_pause = auto_pause
        self.metadata_displays = []

    def register_metadata_display(self, mddisplay):
        self.metadata_displays.append(mddisplay)

    def metadata_notify(self, metadata):
        for md in self.metadata_displays:
            md.metadata(metadata)

    def retrievePlayers(self):
        """
        Returns a list of all MPRIS enabled players that are active in 
        the system
        """
        return [name for name in self.bus.list_names()
                if name.startswith("org.mpris")]

    def retrieveState(self, name):
        """
        Returns the playback state for the given player instance
        """
        try:
            proxy = self.bus.get_object(name, "/org/mpris/MediaPlayer2")
            device_prop = dbus.Interface(
                proxy, "org.freedesktop.DBus.Properties")
            state = device_prop.Get("org.mpris.MediaPlayer2.Player",
                                    "PlaybackStatus")
            return state
        except:
            return None

    def retrieveMeta(self, name):
        """
        Return the metadata for the given player instance
        """
        try:
            proxy = self.bus.get_object(name, "/org/mpris/MediaPlayer2")
            device_prop = dbus.Interface(
                proxy, "org.freedesktop.DBus.Properties")
            prop = device_prop.Get(
                "org.mpris.MediaPlayer2.Player", "Metadata")
            try:
                artist = array_to_string(prop.get("xesam:artist"))
            except:
                artist = None

            try:
                title = str(prop.get("xesam:title"))
            except:
                title = None

            try:
                albumArtist = array_to_string(prop.get("xesam:albumArtist"))
            except:
                albumArtist = None

            try:
                albumTitle = str(prop.get("xesam:album"))
            except:
                albumTitle = None

            try:
                artURL = str(prop.get("mpris:artUrl"))
            except:
                artURL = None

            try:
                discNumber = str(prop.get("xesam:discNumber"))
            except:
                discNumber = None

            try:
                trackNumber = str(prop.get("xesam:trackNumber"))
            except:
                trackNumber = None

            md = Metadata(artist, title, albumArtist, albumTitle,
                          artURL, discNumber, trackNumber)

            md.playerName = self.playername(name)

            md.fixProblems()

            return md

        except dbus.exceptions.DBusException as e:
            logging.debug(e)

    def mpris_command(self, playername, command):
        if command in mpris_commands:
            proxy = self.bus.get_object(playername,
                                        "/org/mpris/MediaPlayer2")
            player = dbus.Interface(
                proxy, dbus_interface='org.mpris.MediaPlayer2.Player')

            run_command = getattr(player, command,
                                  lambda: "Unknown command")
            return run_command()
        else:
            raise RuntimeError("MPRIS command {} not supported".format(
                command))

    def pause_inactive(self, active_player):
        """
        Automatically pause other player if playback was started 
        on a new player
        """
        for p in self.state_table:
            if (p != active_player) and \
                    (self.state_table[p].state == PLAYING):
                logging.info("Pausing " + self.playername(p))
                self.mpris_command(p, MPRIS_PAUSE)

    def pause_all(self):
        for player in self.state_table:
            self.mpris_command(player, MPRIS_PAUSE)

    def print_players(self):
        for p in self.state_table:
            print(self.playername(p))

    def playername(self, mprisname):
        if (mprisname.startswith("org.mpris.MediaPlayer2.")):
            return mprisname[23:]
        else:
            return mprisname

    def main_loop(self):
        """ 
        Main loop: 
        - monitors state of all players
        - pauses players if a new player starts palyback
        """

        finished = False
        md = Metadata()
        active_players = set()
        while not(finished):
            new_player_started = None

            for p in self.retrievePlayers():

                if p not in self.state_table:
                    self.state_table[p] = PlayerState()

                try:
                    state = self.retrieveState(p).lower()
                except:
                    logging.info("Got no state from " + p)
                    state = "unknown"
                self.state_table[p].state = state

                # Check if playback started on a player that wasn't
                # playing before
                if state == PLAYING:
                    if (p not in active_players):
                        new_player_started = p
                        active_players.add(p)

                    md_old = self.state_table[p].metadata
                    md = self.retrieveMeta(p)

                    self.state_table[p].metadata = md
                    if md is not None:
                        if not(md.sameSong(md_old)):
                            self.metadata_notify(md)
                else:
                    if p in active_players:
                        active_players.remove(p)

            if new_player_started is not None:
                if self.auto_pause:
                    logging.info(
                        "new player started, pausing other active players")
                    self.pause_inactive(new_player_started)
                else:
                    logging.debug("auto-pause disabled")

            time.sleep(0.2)

    def __str__(self):
        """
        String representation of the current state: all players,
        playback state and meta data
        """
        res = ""
        for p in self.state_table:
            res = res + "{:30s} - {:10s}: {}/{}\n".format(
                self.playername(p),
                self.state_table[p].state,
                self.state_table[p].metadata.artist,
                self.state_table[p].metadata.title)

        return res
