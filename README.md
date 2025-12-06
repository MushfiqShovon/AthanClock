# Athan Clock 🕌

An automated Islamic prayer time application for Linux systems that fetches prayer times from the internet and plays Athan (call to prayer) at the correct times throughout the day.

## Features

- 🌍 Automatically fetches prayer times based on your location
- 🔔 Plays Athan audio files at each prayer time
- 🎵 Different Athan recordings for Fajr and other prayers
- 🔄 Auto-updates prayer times daily
- 🗣️ Voice announcements using text-to-speech
- 🚀 Easy setup with automated dependency installation
- 🔧 Background service management (start, stop, restart)
- 🌅 Optional auto-start on system boot
- 📊 Built-in logging and status checking

## Prerequisites

This application is designed for **Linux systems** (tested on Debian/Ubuntu-based distributions, including Raspberry Pi).

## Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MushfiqShovon/AthanClock.git
   cd AthanClock
   ```

2. **Make the setup script executable:**
   ```bash
3. **Install dependencies and set up the application:**
   ```bash
   ./RunAthan.sh install
   ```

   Or for a complete setup (install + start + enable startup):
   ```bash
   ./RunAthan.sh
   ```

The setup will automatically:
- Check for required packages (`python3`, `espeak`, `mpg123`)
- Install any missing dependencies
- Start the application in background
- Enable auto-start on system boottically:
- Check for required packages (`python3`, `espeak`, `mpg123`)
- Install any missing dependencies
- Start the prayer clock application

## Configuration

Before running, you may want to customize the settings in `prayer_clock.py`:

```python
# ========= CONFIG =========
CITY = "Morgantown"           # Your city name
COUNTRY = "USA"               # Your country
METHOD = 2                    # Calculation method (see below)
PLAYER = "mpg123"  # Audio player command
# ==========================
```

### Calculation Methods

The `METHOD` parameter determines which calculation method to use for prayer times:

- `1` - University of Islamic Sciences, Karachi
- `2` - Muslim World League (default)
- `3` - Egyptian General Authority of Survey
- `4` - Umm Al-Qura University, Makkah
- `5` - Islamic Society of North America (ISNA)

For more methods, visit: [Aladhan API Documentation](http://api.aladhan.com/v1/methods)

## Audio Files

The application requires the following audio files in the project directory:

## Usage

The `RunAthan.sh` script provides easy management of the Athan Clock service:

### Available Commands

```bash
./RunAthan.sh [command]
```

**Commands:**

- `install` - Install required dependencies only
- `start` - Start Athan Clock in background
- `stop` - Stop the running Athan Clock
- `restart` - Restart Athan Clock
- `status` - Check if Athan Clock is running
- `enable-startup` - Enable auto-start on system boot
- `disable-startup` - Remove from system startup
- `logs` - View the last 50 lines of application logs
- *(no command)* - Complete setup: install + start + enable startup

### Common Usage Examples

**First time setup:**
```bash
./RunAthan.sh install    # Install dependencies
./RunAthan.sh start      # Start the application
./RunAthan.sh enable-startup  # Enable auto-start on boot
```

**Quick setup (all-in-one):**
## How It Works

1. **Fetches Prayer Times**: Uses the [Aladhan API](http://api.aladhan.com) to get daily prayer times based on your location
2. **Calculates Wait Time**: Determines how long to wait until the next prayer
3. **Plays Athan**: At each prayer time, plays the appropriate audio file
4. **Daily Reset**: Automatically fetches new times at midnight for the next day
5. **Background Service**: Runs as a daemon process, continuing even after terminal closes
## Troubleshooting

### Check Application Status
```bash
./RunAthan.sh status
./RunAthan.sh logs
```

### No Sound Output
- Check audio device configuration in `PLAYER` variable
- Test with: `mpg123 athan_fajr.mp3`
- For different audio output, modify: `mpg123 -a hw:X,Y` (find devices with `aplay -l`)
- Check logs: `./RunAthan.sh logs`

### Cannot Fetch Prayer Times
- Check internet connection
- Verify city/country names are correct in `prayer_clock.py`
- The application will retry every 2 minutes if fetching fails
- View errors with: `./RunAthan.sh logs`

### Application Won't Start
- Check if already running: `./RunAthan.sh status`
- Stop and restart: `./RunAthan.sh restart`
- Check for errors: `./RunAthan.sh logs`

### Permission Denied
```bash
chmod +x RunAthan.sh
chmod +x prayer_clock.py
```

### Remove from Startup
If you no longer want the application to start automatically:
```bash
./RunAthan.sh disable-startup
```

### Completely Stop the Application
```bash
./RunAthan.sh stop
./RunAthan.sh disable-startup
```unAthan.sh disable-startup
```

### Manual Start (Advanced)
If you prefer to run directly without the management script:
```bash
python3 prayer_clock.py
```ntab -e
   ```

2. Add this line (replace `/path/to/AthanClock` with actual path):
   ```
   @reboot sleep 30 && /path/to/AthanClock/RunAthan.sh >> /tmp/athan_log.txt 2>&1
   ```

## How It Works

1. **Fetches Prayer Times**: Uses the [Aladhan API](http://api.aladhan.com) to get daily prayer times based on your location
2. **Calculates Wait Time**: Determines how long to wait until the next prayer
3. **Plays Athan**: At each prayer time, plays the appropriate audio file
4. **Daily Reset**: Automatically fetches new times at midnight for the next day

## Troubleshooting

### No Sound Output
- Check audio device configuration in `PLAYER` variable
- Test with: `mpg123 athan_fajr.mp3`
- For different audio output, modify: `mpg123 -a hw:X,Y` (find devices with `aplay -l`)

### Cannot Fetch Prayer Times
- Check internet connection
- Verify city/country names are correct
- The application will retry every 2 minutes if fetching fails

### Permission Denied
```bash
chmod +x RunAthan.sh
chmod +x prayer_clock.py
```

## Dependencies

- **Python 3** - Programming language
- **python3-requests** - HTTP library for API calls (installed automatically via pip)
- **espeak** - Text-to-speech engine
- **mpg123** - MP3 audio player

All dependencies are automatically installed by `RunAthan.sh`.

## API Reference

This application uses the [Aladhan Prayer Times API](http://api.aladhan.com/).

Example API call:
```
http://api.aladhan.com/v1/timingsByCity?city=Morgantown&country=USA&method=2
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available for personal and educational use.

## Acknowledgments

- Prayer times provided by [Aladhan API](http://api.aladhan.com)
- Developed for use on Raspberry Pi and Linux systems

## Support

For issues, questions, or suggestions, please open an issue on the [GitHub repository](https://github.com/MushfiqShovon/AthanClock).

---
