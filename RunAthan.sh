#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/prayer_clock.py"
PACKAGES=("python3" "espeak" "mpg123")

echo "=== Athan Clock Setup Starting ==="

# Function to check and install package
install_if_missing() {
    PKG=$1
    if ! dpkg -l | grep -q "^ii  $PKG "; then
        echo "📦 $PKG not installed — installing..."
        sudo apt update
        sudo apt install -y "$PKG"
    else
        echo "✔ $PKG already installed."
    fi
}

# Loop through required packages
for PACKAGE in "${PACKAGES[@]}"; do
    install_if_missing "$PACKAGE"
done

echo "=== All required software installed ==="

# Run the python script
echo "Running prayer_clock.py..."
python3 "$PY_SCRIPT"

