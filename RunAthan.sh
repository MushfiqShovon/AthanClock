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
CONFIG_FILE="$SCRIPT_DIR/config.json"
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

configure() {
    # Read answers from the terminal, even when this script was piped from curl
    if ! { : < /dev/tty; } 2>/dev/null; then
        echo "No terminal available, skipping location setup."
        echo "Run '$0 configure' later to set your city."
        return
    fi

    echo
    echo "=== Location setup ==="
    local city="" state="" country="" method=""
    while [ -z "$city" ]; do
        read -r -p "City (e.g. London): " city < /dev/tty
    done
    read -r -p "State/region (optional, press Enter to skip): " state < /dev/tty
    while [ -z "$country" ]; do
        read -r -p "Country (e.g. UK or United Kingdom): " country < /dev/tty
    done
    echo "Calculation method: 1=Karachi, 2=ISNA (North America), 3=Muslim World League,"
    echo "                    4=Umm Al-Qura (Makkah), 5=Egyptian. Others: see README."
    while ! [[ "$method" =~ ^[0-9]+$ ]]; do
        read -r -p "Method [2]: " method < /dev/tty
        method="${method:-2}"
    done

    python3 - "$CONFIG_FILE" "$city" "$state" "$country" "$method" <<'EOF'
import json, sys
path, city, state, country, method = sys.argv[1:]
with open(path, "w") as f:
    json.dump({"city": city, "state": state, "country": country, "method": int(method)}, f, indent=2)
EOF
    echo "Saved to $CONFIG_FILE"

    # Show today's times so the user can confirm the location was understood
    python3 - "$city" "$state" "$country" "$method" <<'EOF' || true
import sys, requests
city, state, country, method = sys.argv[1:]
params = {"city": city, "country": country, "method": method}
# The API's city lookup often fails with a state, so fall back to city + country
attempts = [{**params, "state": state}, params] if state else [params]
try:
    for p in attempts:
        data = requests.get("https://api.aladhan.com/v1/timingsByCity", params=p, timeout=10).json()
        if data.get("code") == 200:
            break
    t = data["data"]["timings"]
    tz = data["data"]["meta"]["timezone"]
    print(f"Today's times ({tz}):")
    for name in ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]:
        print(f"  {name:8} {t[name]}")
    print("If these look wrong, run './RunAthan.sh configure' again.")
except Exception:
    print("Could not check the location online right now; the app will retry when it runs.")
EOF
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

uninstall_app() {
    systemctl --user disable --now "$SERVICE_NAME" 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl --user daemon-reload
    echo "Athan Clock service removed. It will not run again."
    echo "To delete the app files too, run:  rm -rf '$SCRIPT_DIR'"
}

# Write config.json from setup options (used by the website's install command)
save_config() {
    python3 - "$CONFIG_FILE" "$@" <<'EOF'
import json, sys
path, city, state, country, method, lat, lon = sys.argv[1:]
config = {"city": city, "state": state, "country": country, "method": int(method)}
if lat and lon:
    config["latitude"] = float(lat)
    config["longitude"] = float(lon)
with open(path, "w", encoding="utf-8") as f:
    json.dump(config, f, indent=2, ensure_ascii=False)
EOF
    echo "Location saved to $CONFIG_FILE: $city${state:+, $state}, $country (method $method)"
}

setup() {
    local city="" state="" country="" method="" lat="" lon=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --city)    city="$2"; shift 2 ;;
            --state)   state="$2"; shift 2 ;;
            --country) country="$2"; shift 2 ;;
            --method)  method="$2"; shift 2 ;;
            --lat)     lat="$2"; shift 2 ;;
            --lon)     lon="$2"; shift 2 ;;
            *) echo "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
    if [ -n "$method" ] && ! [[ "$method" =~ ^[0-9]+$ ]]; then
        echo "--method must be a number"; exit 1
    fi
    num='^-?[0-9]+(\.[0-9]+)?$'
    if { [ -n "$lat" ] && ! [[ "$lat" =~ $num ]]; } || { [ -n "$lon" ] && ! [[ "$lon" =~ $num ]]; }; then
        echo "--lat and --lon must be numbers"; exit 1
    fi

    install_deps
    if [ -n "$city" ] && [ -n "$country" ]; then
        save_config "$city" "$state" "$country" "${method:-2}" "$lat" "$lon"
    elif [ ! -f "$CONFIG_FILE" ]; then
        configure
    fi
    enable_startup
    start_app
}

usage() {
    cat <<EOF
Usage: $0 [command]

Commands:
  install          Install required packages
  configure        Set your city/country and calculation method
  start            Start Athan Clock
  stop             Stop Athan Clock
  restart          Restart Athan Clock
  status           Show whether Athan Clock is running
  enable-startup   Start Athan Clock automatically on boot
  disable-startup  Do not start Athan Clock on boot
  logs             Show the last 50 log lines
  uninstall        Stop Athan Clock and remove its service
  (no command)     Full setup: install + configure (first time) + enable-startup + start

Setup options (skip the location questions):
  $0 setup --city NAME --country NAME [--state NAME] [--method N] [--lat N --lon N]
EOF
}

case "${1:-}" in
    install)         install_deps ;;
    configure)
        configure
        if systemctl --user is-active --quiet "$SERVICE_NAME"; then start_app; fi
        ;;
    start)           start_app ;;
    stop)            stop_app ;;
    restart)         start_app ;;
    status)          show_status ;;
    enable-startup)  enable_startup ;;
    disable-startup) disable_startup ;;
    logs)            show_logs ;;
    uninstall)       uninstall_app ;;
    ""|setup)        [ $# -gt 0 ] && shift; setup "$@" ;;
    -h|--help|help)  usage ;;
    *)               usage; exit 1 ;;
esac
