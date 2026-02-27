#!/bin/bash
# kiosk-mode.sh — Set up or revert kiosk mode on HiFiBerry OS
#
# Kiosk stack: getty@tty1 autologin → cage (Wayland compositor) → cog (WPE WebKit)
# No display manager, no desktop — just a browser on the screen.
#
# Usage:
#   sudo ./kiosk-mode.sh setup [--url=URL] [--scale=FACTOR]
#   sudo ./kiosk-mode.sh revert
#   sudo ./kiosk-mode.sh status
#
# Defaults: URL=http://localhost/now-playing-minimal  SCALE=1.3

set -e

KIOSK_USER="${SUDO_USER:-$(logname 2>/dev/null || echo matuschd)}"
KIOSK_URL="http://localhost/now-playing-minimal"
KIOSK_SCALE="1.3"
AUTOLOGIN_DIR="/etc/systemd/system/getty@tty1.service.d"
AUTOLOGIN_CONF="${AUTOLOGIN_DIR}/autologin.conf"
USER_HOME="$(getent passwd "$KIOSK_USER" | cut -d: -f6)"
BASH_PROFILE="${USER_HOME}/.bash_profile"
BASH_PROFILE_BACKUP="${BASH_PROFILE}.desktop-backup"

# ── helpers ──────────────────────────────────────────────────────────────────

die() { echo "ERROR: $*" >&2; exit 1; }

require_root() {
    [ "$(id -u)" = "0" ] || die "Run with sudo: sudo $0 $*"
}

is_kiosk_active() {
    [ -f "$AUTOLOGIN_CONF" ] && grep -q "autologin" "$AUTOLOGIN_CONF" 2>/dev/null
}

# ── setup ────────────────────────────────────────────────────────────────────

cmd_setup() {
    require_root
    [ -n "$KIOSK_USER" ] || die "Could not determine target user."
    [ -d "$USER_HOME" ]  || die "Home directory not found for user '$KIOSK_USER'."

    if is_kiosk_active; then
        echo "Kiosk mode already configured — updating settings..."
    else
        echo "Setting up kiosk mode for user '$KIOSK_USER'..."
    fi

    # 1. Install dependencies
    echo "  [1/5] Installing cage and cog..."
    apt-get install -y --no-install-recommends cage cog >/dev/null

    # 2. Disable lightdm
    echo "  [2/5] Disabling lightdm..."
    systemctl disable lightdm 2>/dev/null || true
    systemctl stop lightdm 2>/dev/null || true

    # 3. Configure getty@tty1 autologin
    echo "  [3/5] Configuring getty@tty1 autologin..."
    mkdir -p "$AUTOLOGIN_DIR"
    cat > "$AUTOLOGIN_CONF" <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin ${KIOSK_USER} --noclear %I \$TERM
EOF

    # 4. Write ~/.bash_profile (back up existing one if it's not already ours)
    echo "  [4/5] Writing ~/.bash_profile..."
    if [ -f "$BASH_PROFILE" ] && ! grep -q "cage.*cog\|cog.*kiosk" "$BASH_PROFILE" 2>/dev/null; then
        cp "$BASH_PROFILE" "$BASH_PROFILE_BACKUP"
        echo "        (backed up original to ${BASH_PROFILE_BACKUP})"
    fi
    cat > "$BASH_PROFILE" <<BASHEOF
# HiFiBerry kiosk mode — launch browser on tty1 only, not on SSH
if [ "\$(tty)" = "/dev/tty1" ] && [ -z "\$SSH_TTY" ]; then
    sleep 2
    export COG_PLATFORM_DRM_CURSOR=0
    exec cage -- /usr/bin/cog --platform=wl --scale=${KIOSK_SCALE} "${KIOSK_URL}?dark" >/tmp/kiosk.log 2>&1
fi
BASHEOF
    chown "$KIOSK_USER:$KIOSK_USER" "$BASH_PROFILE"

    # 5. Reload systemd and restart getty
    echo "  [5/5] Reloading systemd..."
    systemctl daemon-reload
    systemctl reset-failed getty@tty1 2>/dev/null || true
    systemctl restart getty@tty1

    echo ""
    echo "Done. Kiosk mode configured."
    echo "  URL    : $KIOSK_URL"
    echo "  Scale  : $KIOSK_SCALE"
    echo "  User   : $KIOSK_USER"
    echo "  Log    : /tmp/kiosk.log (on device)"
    echo ""
    echo "Reboot the device to apply cleanly: sudo reboot"
}

# ── revert ───────────────────────────────────────────────────────────────────

cmd_revert() {
    require_root

    echo "Reverting to normal desktop..."

    # 1. Remove getty autologin override
    echo "  [1/3] Removing getty@tty1 autologin override..."
    rm -f "$AUTOLOGIN_CONF"
    rmdir "$AUTOLOGIN_DIR" 2>/dev/null || true

    # 2. Restore ~/.bash_profile
    echo "  [2/3] Restoring ~/.bash_profile..."
    if [ -f "$BASH_PROFILE_BACKUP" ]; then
        mv "$BASH_PROFILE_BACKUP" "$BASH_PROFILE"
        echo "        (restored from backup)"
    else
        rm -f "$BASH_PROFILE"
        echo "        (no backup found — removed kiosk profile)"
    fi

    # 3. Re-enable and start lightdm
    echo "  [3/3] Re-enabling lightdm..."
    systemctl daemon-reload
    systemctl enable lightdm

    echo ""
    echo "Done. Normal desktop restored."
    echo "Reboot to apply: sudo reboot"
}

# ── status ───────────────────────────────────────────────────────────────────

cmd_status() {
    echo "Kiosk mode status:"
    if is_kiosk_active; then
        echo "  Active   : YES"
        echo "  Autologin: $AUTOLOGIN_CONF"
        if [ -f "$BASH_PROFILE" ]; then
            URL=$(grep -oP 'http\S+' "$BASH_PROFILE" | head -1)
            SCALE=$(grep -oP '(?<=--scale=)\S+' "$BASH_PROFILE" | head -1)
            echo "  URL      : ${URL:-unknown}"
            echo "  Scale    : ${SCALE:-unknown}"
        fi
    else
        echo "  Active   : NO (normal desktop)"
    fi
    echo "  lightdm  : $(systemctl is-enabled lightdm 2>/dev/null || echo unknown)"
    if pgrep -x cage >/dev/null 2>&1; then
        echo "  cage     : running"
    else
        echo "  cage     : not running"
    fi
}

# ── main ─────────────────────────────────────────────────────────────────────

usage() {
    echo "Usage: sudo $0 {setup [--url=URL] [--scale=FACTOR]|revert|status}"
    echo ""
    echo "  setup     Configure kiosk mode"
    echo "    --url=URL       Page to display (default: http://localhost/now-playing-minimal)"
    echo "    --scale=FACTOR  Browser zoom factor (default: 1.3)"
    echo "  revert    Restore normal RPD desktop"
    echo "  status    Show current kiosk mode state"
    exit 1
}

case "$1" in
    setup)
        shift
        for arg in "$@"; do
            case "$arg" in
                --url=*)   KIOSK_URL="${arg#--url=}" ;;
                --scale=*) KIOSK_SCALE="${arg#--scale=}" ;;
                *) die "Unknown option: $arg" ;;
            esac
        done
        cmd_setup
        ;;
    revert)
        cmd_revert
        ;;
    status)
        cmd_status
        ;;
    *)
        usage
        ;;
esac
