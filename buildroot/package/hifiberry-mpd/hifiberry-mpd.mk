################################################################################
#
# hifiberry-mpd
#
################################################################################

# based on the original mpd package but with additional patches

HIFIBERRY_MPD_VERSION_MAJOR = 0.21
HIFIBERRY_MPD_VERSION = $(MPD_VERSION_MAJOR).16
HIFIBERRY_MPD_SOURCE = mpd-$(MPD_VERSION).tar.xz
HIFIBERRY_MPD_SITE = http://www.musicpd.org/download/mpd/$(MPD_VERSION_MAJOR)
HIFIBERRY_MPD_DEPENDENCIES = host-pkgconf boost
HIFIBERRY_MPD_LICENSE = GPL-2.0+
HIFIBERRY_MPD_LICENSE_FILES = COPYING

# enable Zeroconf
HIFIBERRY_MPD_DEPENDENCIES += avahi
HIFIBERRY_MPD_CONF_OPTS += -Dzeroconf=avahi

# enable ICU
HIFIBERRY_MPD_DEPENDENCIES += icu
HIFIBERRY_MPD_CONF_OPTS += -Dicu=enabled

# enable ALSA
HIFIBERRY_MPD_DEPENDENCIES += alsa-lib
HIFIBERRY_MPD_CONF_OPTS += -Dalsa=enabled

# disable AO
HIFIBERRY_MPD_CONF_OPTS += -Dao=disabled

# disable audiofile
HIFIBERRY_MPD_CONF_OPTS += -Daudiofile=disabled

# disable BZIP2
HIFIBERRY_MPD_CONF_OPTS += -Dbzip2=disabled

# disable CDIO
HIFIBERRY_MPD_CONF_OPTS += -Dcdio_paranoia=disabled

# enable CURL
HIFIBERRY_MPD_DEPENDENCIES += libcurl
HIFIBERRY_MPD_CONF_OPTS += -Dcurl=enabled

# enable DSD
HIFIBERRY_MPD_CONF_OPTS += -Ddsd=true

# enable AAC
HIFIBERRY_MPD_DEPENDENCIES += faad2
HIFIBERRY_MPD_CONF_OPTS += -Dfaad=enabled

#enable FFMPEG
HIFIBERRY_MPD_DEPENDENCIES += ffmpeg
HIFIBERRY_MPD_CONF_OPTS += -Dffmpeg=enabled

# enable FLAC
HIFIBERRY_MPD_DEPENDENCIES += flac
HIFIBERRY_MPD_CONF_OPTS += -Dflac=enabled

# disable HTTP output
HIFIBERRY_MPD_CONF_OPTS += -Dhttpd=false

# disable jack
HIFIBERRY_MPD_CONF_OPTS += -Djack=disabled

# enable LAME
HIFIBERRY_MPD_DEPENDENCIES += lame
HIFIBERRY_MPD_CONF_OPTS += -Dlame=enabled

# enable mpdclient
HIFIBERRY_MPD_DEPENDENCIES += libmpdclient
HIFIBERRY_MPD_CONF_OPTS += -Dlibmpdclient=enabled

# disable libmms
HIFIBERRY_MPD_CONF_OPTS += -Dmms=disabled

# disable NFS
HIFIBERRY_MPD_CONF_OPTS += -Dnfs=disabled

# enable smb
HIFIBERRY_MPD_DEPENDENCIES += samba4
HIFIBERRY_MPD_CONF_OPTS += -Dsmbclient=enabled

# enable sample rate converter
HIFIBERRY_MPD_DEPENDENCIES += libsamplerate
HIFIBERRY_MPD_CONF_OPTS += -Dlibsamplerate=enabled

# enable sndfile
HIFIBERRY_MPD_DEPENDENCIES += libsndfile
HIFIBERRY_MPD_CONF_OPTS += -Dsndfile=enabled

# disable sox resampling
HIFIBERRY_MPD_CONF_OPTS += -Dsoxr=disabled

# enable libmad
HIFIBERRY_MPD_DEPENDENCIES += libid3tag libmad
HIFIBERRY_MPD_CONF_OPTS += -Dmad=enabled

# disable mpg123
HIFIBERRY_MPD_CONF_OPTS += -Dmpg123=disabled

# disable musepack
HIFIBERRY_MPD_CONF_OPTS += -Dmpcdec=disabled

# enable neighbor discovery
HIFIBERRY_MPD_CONF_OPTS += -Dneighbor=true

# enable OGG
HIFIBERRY_MPD_DEPENDENCIES += opus libogg
HIFIBERRY_MPD_CONF_OPTS += -Dopus=enabled

# disable OSS
HIFIBERRY_MPD_CONF_OPTS += -Doss=disabled

# disable pulseaudio
HIFIBERRY_MPD_CONF_OPTS += -Dpulse=disabled

# enable Qobuz
HIFIBERRY_MPD_DEPENDENCIES += libgcrypt yajl
HIFIBERRY_MPD_CONF_OPTS += -Dqobuz=enabled

# enable shoutcast
HIFIBERRY_MPD_DEPENDENCIES += libshout
HIFIBERRY_MPD_CONF_OPTS += -Dshout=enabled

# enable soundcloud
HIFIBERRY_MPD_DEPENDENCIES += yajl
HIFIBERRY_MPD_CONF_OPTS += -Dsoundcloud=enabled

# enable sqlite
HIFIBERRY_MPD_DEPENDENCIES += sqlite
HIFIBERRY_MPD_CONF_OPTS += -Dsqlite=enabled

# enable TCP
HIFIBERRY_MPD_CONF_OPTS += -Dtcp=true

# disable TIDAL (not working at all)
HIFIBERRY_MPD_CONF_OPTS += -Dtidal=disabled

# disable tremor
HIFIBERRY_MPD_CONF_OPTS += -Dtremor=disabled

# disable twolame
HIFIBERRY_MPD_CONF_OPTS += -Dtwolame=disabled

# enable UPnP
HIFIBERRY_MPD_DEPENDENCIES += \
	expat \
	$(if $(BR2_PACKAGE_LIBUPNP),libupnp,libupnp18)
HIFIBERRY_MPD_CONF_OPTS += -Dupnp=enabled

# enable vorbis
HIFIBERRY_MPD_DEPENDENCIES += libvorbis
HIFIBERRY_MPD_CONF_OPTS += -Dvorbis=enabled -Dvorbisenc=enabled

# enable wavpack
HIFIBERRY_MPD_DEPENDENCIES += wavpack
HIFIBERRY_MPD_CONF_OPTS += -Dwavpack=enabled

define HIFIBERRY_MPD_INSTALL_EXTRA_FILES
	mkdir -p $(TARGET_DIR)/library
	mkdir -p $(TARGET_DIR)/library/music
	mkdir -p $(TARGET_DIR)/library/playlists
        mkdir -p $(TARGET_DIR)/var/lib/mpd
	$(INSTALL) -D -m 0755 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/pause-state-file \
		$(TARGET_DIR)/opt/hifiberry/bin/pause-state-file
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/mpd.conf \
		$(TARGET_DIR)/etc/mpd.conf
	$(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/mpd.conf \
		$(TARGET_DIR)/etc/mpd.conf.default
        # Install some sample web radio files
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/radio/*.m3u \
                $(TARGET_DIR)/library/playlists/
	mkdir -p $(TARGET_DIR)/var/lib/mpd
endef

HIFIBERRY_MPD_POST_INSTALL_TARGET_HOOKS += HIFIBERRY_MPD_INSTALL_EXTRA_FILES

define HIFIBERRY_MPD_INSTALL_INIT_SYSTEMD
        $(INSTALL) -D -m 0644 $(BR2_EXTERNAL_HIFIBERRY_PATH)/package/hifiberry-mpd/mpd.service \
                $(TARGET_DIR)/usr/lib/systemd/system/mpd.service
        ln -fs ../../../../usr/lib/systemd/system/shairport-sync.service \
                $(TARGET_DIR)/etc/systemd/system/multi-user.target.wants/mpd.service
endef


$(eval $(meson-package))
