#!/bin/bash
# One-line installer for Athan Clock:
#   curl -fsSL https://raw.githubusercontent.com/MushfiqShovon/AthanClock/main/install.sh | bash
#
# Optional location settings (the website builds these for you):
#   ... | bash -s -- --city 'Morgantown' --state 'West Virginia' --country 'United States' \
#                    --method 2 --lat 39.6295 --lon -79.9559
#
# Downloads (or updates) the app into ~/AthanClock and runs the full setup.

set -e

REPO_URL="https://github.com/MushfiqShovon/AthanClock.git"
INSTALL_DIR="$HOME/AthanClock"
# Only the app is downloaded; the website (docs/), dev tools and README are skipped
SPARSE_PATTERNS=('/*' '!/docs/' '!/tools/' '!/README.md')

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
        # Also trims older full installs down to just the app files
        git -C "$INSTALL_DIR" sparse-checkout set --no-cone "${SPARSE_PATTERNS[@]}"
        git -C "$INSTALL_DIR" pull --ff-only
    else
        echo "Downloading Athan Clock into $INSTALL_DIR..."
        # Shallow, partial clone: files outside the sparse patterns are never downloaded
        git clone --depth 1 --filter=blob:none --no-checkout "$REPO_URL" "$INSTALL_DIR"
        git -C "$INSTALL_DIR" sparse-checkout set --no-cone "${SPARSE_PATTERNS[@]}"
        git -C "$INSTALL_DIR" checkout
    fi

    chmod +x "$INSTALL_DIR/RunAthan.sh"
    "$INSTALL_DIR/RunAthan.sh" setup "$@" < /dev/null

    echo
    echo "Done! Athan Clock is installed in $INSTALL_DIR and will start on every boot."
    echo "Change location:   $INSTALL_DIR/RunAthan.sh configure"
    echo "Turn it off:       $INSTALL_DIR/RunAthan.sh stop && $INSTALL_DIR/RunAthan.sh disable-startup"
    echo "Remove it:         $INSTALL_DIR/RunAthan.sh uninstall"
}

main "$@"
