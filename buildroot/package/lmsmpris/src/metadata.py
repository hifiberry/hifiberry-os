import logging
import datetime
import time

import pylast


class Metadata:
    """
    Class to start metadata of a song
    """

    def __init__(self, artist=None, title=None,
                 albumArtist=None, albumTitle=None, artUrl=None,
                 discNumber=None, trackNumber=None,
                 playerName=None):
        self.artist = artist
        self.title = title
        self.albumArtist = albumArtist
        self.albumTitle = albumTitle
        self.artUrl = artUrl
        self.discNumber = discNumber
        self.tracknumber = trackNumber
        self.playerName = playerName

    def sameSong(self, other):
        if not isinstance(other, Metadata):
            return NotImplemented

        return self.artist == other.artist and self.title == other.title

    def fixProblems(self):
        """
        Cleanup metadata for known problems
        """

        # unknown artist, but artist - title in title
        # seen on mpd web radio streams
        if (self.playerName == "mpd") and \
            (self.artist == "unknown artist") and \
                (" - " in self.title):
            [artist, title] = self.title.split(" - ", 1)
            self.artist = artist
            self.title = title

    def __str__(self):
        return "{}: {} ({}) {}".format(self.artist, self.title,
                                       self.albumTitle, self.artUrl)


class MetadataDisplay:

    def __init__(self):
        pass

    def metadata(self, metadata):
        pass


class MetadataConsole(MetadataDisplay):

    def __init__(self):
        super()
        pass

    def metadata(self, metadata):
        print("{:16s}: {}".format(metadata.playerName, metadata))


class MetadataScrobbler(MetadataDisplay):

    def __init__(self, API_KEY, API_SECRET,
                 lastfm_username, lastfm_password,
                 lastfm_password_hash=None,
                 network="lastfm"):
        if lastfm_password_hash is None:
            lastfm_password_hash = pylast.md5(lastfm_password)

        network = network.lower()

        if network == "lastfm":
            self.network = pylast.LastFMNetwork(
                api_key=API_KEY,
                api_secret=API_SECRET,
                username=lastfm_username,
                password_hash=lastfm_password_hash)
        elif network == "librefm":
            self.network = pylast.LibreFMNetwork(
                api_key=API_KEY,
                api_secret=API_SECRET,
                username=lastfm_username,
                password_hash=lastfm_password_hash)
        else:
            raise RuntimeError("Network {} unknown".format(network))

    def metadata(self, metadata):
        if (metadata.artist is not None) and \
                (metadata.title is not None):
            try:
                logging.info("scrobbling " + str(metadata))
                unix_timestamp = int(time.mktime(
                    datetime.datetime.now().timetuple()))
                self.network.scrobble(artist=metadata.artist,
                                      title=metadata.title,
                                      timestamp=unix_timestamp)
            except Exception as e:
                logging.error("Could not scrobble %s/%s: %s",
                              metadata.artist,
                              metadata.title,
                              e)
