#!/bin/bash
# One-line installer for Athan Clock:
#   curl -fsSL https://raw.githubusercontent.com/MushfiqShovon/AthanClock/main/install.sh | bash
#
# Downloads (or updates) the app into ~/AthanClock and runs the full setup.

set -e

REPO_URL="https://github.com/MushfiqShovon/AthanClock.git"
INSTALL_DIR="$HOME/AthanClock"

# Everything is inside main so bash reads the whole script before running it
# (needed when the script is piped from curl).
main() {
    if [ "$(id -u)" -eq 0 ]; then
        echo "Please run this installer as your normal user, not with sudo."
        exit 1
    fi

    if ! command -v git >/dev/null 2>&1; then
        echo "Installing git..."
        sudo apt-get update
        sudo apt-get install -y git
    fi

    if [ -d "$INSTALL_DIR/.git" ]; then
        echo "Updating existing install in $INSTALL_DIR..."
        git -C "$INSTALL_DIR" pull --ff-only
    else
        echo "Downloading Athan Clock into $INSTALL_DIR..."
        git clone "$REPO_URL" "$INSTALL_DIR"
    fi

    chmod +x "$INSTALL_DIR/RunAthan.sh"
    "$INSTALL_DIR/RunAthan.sh" < /dev/null

    echo
    echo "Done! Athan Clock is installed in $INSTALL_DIR and will start on every boot."
    echo "Set your city in $INSTALL_DIR/prayer_clock.py, then run:"
    echo "  $INSTALL_DIR/RunAthan.sh restart"
}

main "$@"
