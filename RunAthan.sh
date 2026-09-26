#!/bin/bash
# Athan Clock setup and service manager.
# Runs prayer_clock.py as a systemd *user* service so it can play sound through
# the desktop audio server (PipeWire/PulseAudio), and starts it on every boot.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="prayerclock.service"
SERVICE_DIR="$HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/$SERVICE_NAME"
LOG_FILE="$SCRIPT_DIR/prayerclock.log"
PACKAGES=(python3 python3-requests mpg123)

if [ "$(id -u)" -eq 0 ]; then
    echo "Please run this script as your normal user, not with sudo."
    echo "It will ask for your password when it needs admin rights."
    exit 1
fi

# systemctl --user needs these; they can be missing in some shells
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}"

install_deps() {
    local missing=()
    for pkg in "${PACKAGES[@]}"; do
        dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
    done
    if [ ${#missing[@]} -eq 0 ]; then
        echo "All dependencies are already installed."
    else
        echo "Installing: ${missing[*]}"
        sudo apt-get update
        sudo apt-get install -y "${missing[@]}"
    fi
}

write_service() {
    mkdir -p "$SERVICE_DIR"
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Prayer Clock Athan Player
Wants=pipewire.service pipewire-pulse.service wireplumber.service
After=pipewire.service pipewire-pulse.service wireplumber.service network-online.target

[Service]
ExecStart=/usr/bin/python3 -u $SCRIPT_DIR/prayer_clock.py
WorkingDirectory=$SCRIPT_DIR
StandardOutput=append:$LOG_FILE
StandardError=append:$LOG_FILE
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
EOF
    # The log must be writable by this user (an older root-run setup may own it)
    if [ -e "$LOG_FILE" ] && [ ! -w "$LOG_FILE" ]; then
        sudo chown "$(id -un):$(id -gn)" "$LOG_FILE"
    fi
    systemctl --user daemon-reload
}

remove_old_setup() {
    # Older versions ran as a system service or from crontab; both break audio
    if [ -f "/etc/systemd/system/$SERVICE_NAME" ]; then
        echo "Disabling old system-wide $SERVICE_NAME..."
        sudo systemctl disable --now "$SERVICE_NAME" || true
    fi
    if crontab -l 2>/dev/null | grep -q "RunAthan.sh"; then
        echo "Removing old RunAthan.sh entry from crontab..."
        crontab -l | grep -v "RunAthan.sh" | crontab -
    fi
}

start_app() {
    write_service
    systemctl --user restart "$SERVICE_NAME"
    echo "Athan Clock started. You should hear the startup sound."
}

stop_app() {
    systemctl --user stop "$SERVICE_NAME" 2>/dev/null || true
    echo "Athan Clock stopped."
}

enable_startup() {
    remove_old_setup
    write_service
    systemctl --user enable "$SERVICE_NAME"
    # Linger lets the user service start at boot, before anyone logs in
    sudo loginctl enable-linger "$(id -un)"
    echo "Athan Clock will start automatically on boot."
}

disable_startup() {
    systemctl --user disable "$SERVICE_NAME" 2>/dev/null || true
    echo "Athan Clock will no longer start on boot."
}

show_status() {
    systemctl --user status "$SERVICE_NAME" --no-pager || true
}

show_logs() {
    if [ -f "$LOG_FILE" ]; then
        tail -n 50 "$LOG_FILE"
    else
        echo "No log file yet ($LOG_FILE)."
    fi
}

usage() {
    cat <<EOF
Usage: $0 [command]

Commands:
  install          Install required packages
  start            Start Athan Clock
  stop             Stop Athan Clock
  restart          Restart Athan Clock
  status           Show whether Athan Clock is running
  enable-startup   Start Athan Clock automatically on boot
  disable-startup  Do not start Athan Clock on boot
  logs             Show the last 50 log lines
  (no command)     Full setup: install + enable-startup + start
EOF
}

case "${1:-}" in
    install)         install_deps ;;
    start)           start_app ;;
    stop)            stop_app ;;
    restart)         start_app ;;
    status)          show_status ;;
    enable-startup)  enable_startup ;;
    disable-startup) disable_startup ;;
    logs)            show_logs ;;
    "")              install_deps; enable_startup; start_app ;;
    -h|--help|help)  usage ;;
    *)               usage; exit 1 ;;
esac
