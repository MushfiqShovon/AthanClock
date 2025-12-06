#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PY_SCRIPT="$SCRIPT_DIR/prayer_clock.py"
PACKAGES=("python3" "espeak" "mpg123")
SERVICE_NAME="athan-clock"
PID_FILE="$SCRIPT_DIR/.athan_clock.pid"
LOG_FILE="$SCRIPT_DIR/athan_clock.log"

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

# Function to install dependencies
install_dependencies() {
    echo "=== Athan Clock Setup Starting ==="
    for PACKAGE in "${PACKAGES[@]}"; do
        install_if_missing "$PACKAGE"
    done
    echo "=== All required software installed ==="
}

# Function to start the application in background
start_app() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "⚠️  Athan Clock is already running (PID: $PID)"
            return 1
        else
            rm "$PID_FILE"
        fi
    fi
    
    echo "▶️  Starting Athan Clock in background..."
    nohup python3 "$PY_SCRIPT" >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    echo "✅ Athan Clock started successfully (PID: $(cat $PID_FILE))"
    echo "📄 Logs: $LOG_FILE"
}

# Function to stop the application
stop_app() {
    if [ ! -f "$PID_FILE" ]; then
        echo "⚠️  Athan Clock is not running"
        return 1
    fi
    
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "⏹️  Stopping Athan Clock (PID: $PID)..."
        kill "$PID"
        rm "$PID_FILE"
        echo "✅ Athan Clock stopped successfully"
    else
        echo "⚠️  Process not found. Cleaning up..."
        rm "$PID_FILE"
    fi
}

# Function to check status
check_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "✅ Athan Clock is RUNNING (PID: $PID)"
            echo "📄 Logs: $LOG_FILE"
            return 0
        else
            echo "❌ Athan Clock is NOT RUNNING (stale PID file found)"
            return 1
        fi
    else
        echo "❌ Athan Clock is NOT RUNNING"
        return 1
    fi
}

# Function to enable startup (crontab)
enable_startup() {
    # Check if already in crontab
    if crontab -l 2>/dev/null | grep -q "$SCRIPT_DIR/RunAthan.sh"; then
        echo "⚠️  Startup entry already exists in crontab"
        return 1
    fi
    
    echo "⚙️  Adding Athan Clock to system startup..."
    (crontab -l 2>/dev/null; echo "@reboot sleep 30 && cd $SCRIPT_DIR && $SCRIPT_DIR/RunAthan.sh start >> $LOG_FILE 2>&1") | crontab -
    echo "✅ Athan Clock will now start automatically on system boot"
}

# Function to disable startup
disable_startup() {
    if ! crontab -l 2>/dev/null | grep -q "$SCRIPT_DIR/RunAthan.sh"; then
        echo "⚠️  No startup entry found in crontab"
        return 1
    fi
    
    echo "⚙️  Removing Athan Clock from system startup..."
    crontab -l 2>/dev/null | grep -v "$SCRIPT_DIR/RunAthan.sh" | crontab -
    echo "✅ Athan Clock removed from system startup"
}

# Function to view logs
view_logs() {
    if [ -f "$LOG_FILE" ]; then
        echo "📄 Last 50 lines of log file:"
        echo "================================"
        tail -n 50 "$LOG_FILE"
    else
        echo "⚠️  No log file found at $LOG_FILE"
    fi
}

# Function to show usage
show_usage() {
    echo "Usage: $0 {install|start|stop|restart|status|enable-startup|disable-startup|logs}"
    echo ""
    echo "Commands:"
    echo "  install          - Install required dependencies"
    echo "  start            - Start Athan Clock in background"
    echo "  stop             - Stop Athan Clock"
    echo "  restart          - Restart Athan Clock"
    echo "  status           - Check if Athan Clock is running"
    echo "  enable-startup   - Enable Athan Clock to run on system startup"
    echo "  disable-startup  - Disable Athan Clock from system startup"
    echo "  logs             - View application logs"
    echo ""
    echo "Examples:"
    echo "  $0 install        # First time setup"
    echo "  $0 start          # Start the application"
    echo "  $0 enable-startup # Run on boot"
}

# Main script logic
case "${1:-}" in
    install)
        install_dependencies
        ;;
    start)
        start_app
        ;;
    stop)
        stop_app
        ;;
    restart)
        stop_app
        sleep 2
        start_app
        ;;
    status)
        check_status
        ;;
    enable-startup)
        enable_startup
        ;;
    disable-startup)
        disable_startup
        ;;
    logs)
        view_logs
        ;;
    "")
        # Default behavior: install, start, and enable startup
        install_dependencies
        start_app
        enable_startup
        ;;
    *)
        echo "❌ Unknown command: $1"
        show_usage
        exit 1
        ;;
esac

