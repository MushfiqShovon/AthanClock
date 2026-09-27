# Athan Clock 🕌

An automated Islamic prayer time application for Linux systems that fetches prayer times from the internet and plays Athan (call to prayer) at the correct times throughout the day.

## Features

- 🌍 Automatically fetches prayer times based on your location
- 🔔 Plays Athan audio files at each prayer time
- 🎵 Different Athan recordings for different prayers
- 🔄 Auto-updates prayer times daily
- 🔊 Startup chime so you can hear that the app is running
- 🚀 One-command setup with automated dependency installation
- 🔧 Runs as a systemd user service (start, stop, restart, status)
- 🌅 Starts automatically on boot
- 📊 Built-in logging

## Prerequisites

This application is designed for **Linux systems** with systemd, tested on **Raspberry Pi OS (Bookworm, desktop)**. Sound is played through the desktop audio server (PipeWire/PulseAudio), so it goes to whatever output is selected as default on your Pi.

## Installation

### Quick install (one command)

Open a terminal on the Pi and run (as your normal user, **not** with `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/MushfiqShovon/AthanClock/main/install.sh | bash
```

This downloads the app into `~/AthanClock`, installs everything, and starts it as a background service that runs on every boot. Running the same command again updates to the latest version.

Then set your city (see [Configuration](#configuration)) and run `~/AthanClock/RunAthan.sh restart`.

### Manual install

1. **Clone the repository:**
   ```bash
   git clone https://github.com/MushfiqShovon/AthanClock.git
   cd AthanClock
   ```

2. **Run the setup script** (as your normal user, **not** with `sudo`; it asks for your password when needed):
   ```bash
   chmod +x RunAthan.sh
   ./RunAthan.sh
   ```

That's it. The setup will:
- Install any missing packages (`python3`, `python3-requests`, `mpg123`)
- Create a systemd user service (`~/.config/systemd/user/prayerclock.service`)
- Enable it to start automatically on boot (using `loginctl enable-linger`)
- Start the app. You should hear the startup chime.

The service runs the app from the folder you cloned into, so don't move or delete that folder afterwards (if you do, run `./RunAthan.sh` again from the new location).

## Configuration

Before running, you may want to customize the settings in `prayer_clock.py`:

```python
# ========= CONFIG =========
CITY = "Morgantown"           # Your city name
STATE = "WV"                  # Your state/region
COUNTRY = "US"                # Your country
METHOD = 2                    # Calculation method (see below)
PLAYER = "mpg123 -q"          # Audio player command
# ==========================
```

After changing the config, apply it with `./RunAthan.sh restart`.

### Calculation Methods

The `METHOD` parameter determines which calculation method to use for prayer times:

- `1` - University of Islamic Sciences, Karachi
- `2` - Islamic Society of North America (ISNA) (default)
- `3` - Muslim World League
- `4` - Umm Al-Qura University, Makkah
- `5` - Egyptian General Authority of Survey

For more methods, visit: [Aladhan API Documentation](https://api.aladhan.com/v1/methods)

## Audio Files

The application uses the following audio files in the project directory:

- `athan_fajr.mp3` - For Fajr prayer (disabled by default; uncomment the `Fajr` line in `ATHAN_FILES` to enable)
- `athan_durd.mp3` - For Dhuhr, Asr, and Maghrib prayers
- `athan_esha.mp3` - For Isha prayer
- `startup.mp3` - Short chime played when the app starts

**Note:** These audio files are included in the repository. You can replace any of them with your own mp3 of the same name.

## Usage

The `RunAthan.sh` script manages the Athan Clock service:

```bash
./RunAthan.sh [command]
```

**Commands:**

- `install` - Install required dependencies only
- `start` - Start Athan Clock
- `stop` - Stop Athan Clock
- `restart` - Restart Athan Clock (use after editing the config)
- `status` - Check if Athan Clock is running
- `enable-startup` - Enable auto-start on system boot
- `disable-startup` - Remove from system startup
- `logs` - View the last 50 lines of application logs
- *(no command)* - Complete setup: install + enable startup + start

### Common Usage Examples

**First time setup:**
```bash
./RunAthan.sh
```

**Daily management:**
```bash
./RunAthan.sh status     # Check if running
./RunAthan.sh stop       # Stop the application
./RunAthan.sh start      # Start the application
./RunAthan.sh restart    # Restart the application
./RunAthan.sh logs       # View recent logs
```

**Disable auto-start:**
```bash
./RunAthan.sh disable-startup
```

### Manual Start (for testing)
Stop the service first so the Athan doesn't play twice:
```bash
./RunAthan.sh stop
python3 prayer_clock.py
```

## How It Works

1. **Fetches Prayer Times**: Uses the [Aladhan API](https://aladhan.com/prayer-times-api) to get daily prayer times based on your location
2. **Calculates Wait Time**: Determines how long to wait until the next prayer
3. **Plays Athan**: At each prayer time, plays the appropriate audio file with `mpg123`
4. **Daily Reset**: Automatically fetches new times after midnight for the next day
5. **User Service**: Runs as a systemd *user* service so it can reach the desktop audio server; a system-wide service or cron job can't, which results in no sound
6. **Auto-start**: Starts on boot, and systemd restarts it if it ever crashes

### Service Management

- **Service file**: `~/.config/systemd/user/prayerclock.service`
- **Log File**: `prayerclock.log` in the project folder, containing all application output and errors
- You can also use systemd directly: `systemctl --user status prayerclock`

## Troubleshooting

### Check Application Status
```bash
./RunAthan.sh status
./RunAthan.sh logs
```

After each start the log should show:
```
Athan Application is started. Playing startup sound...
Startup sound played OK.
```

### No Sound Output
- Check that the right output (HDMI / headphone jack) is selected as default in the desktop volume menu
- Test with: `mpg123 startup.mp3`
- Check logs: `./RunAthan.sh logs`. `Startup sound FAILED` means mpg123 couldn't play audio.
- If you set up an older version of this app (system service or crontab), run `./RunAthan.sh` again; it removes the old setup

### Cannot Fetch Prayer Times
- Right after boot, one `Could not connect to Aladhan API` message is normal while the network comes up
- Check internet connection
- Verify city/state/country names are correct in `prayer_clock.py`
- The application will retry every 2 minutes if fetching fails

### Application Won't Start
- Check if already running: `./RunAthan.sh status`
- Stop and restart: `./RunAthan.sh restart`
- Check for errors: `./RunAthan.sh logs`

### Permission Denied
```bash
chmod +x RunAthan.sh
```

### Completely Stop the Application
```bash
./RunAthan.sh stop
./RunAthan.sh disable-startup
```

## Dependencies

- **Python 3** - Programming language
- **python3-requests** - HTTP library for API calls
- **mpg123** - MP3 audio player

All dependencies are automatically installed by `RunAthan.sh`.

## API Reference

This application uses the [Aladhan Prayer Times API](https://aladhan.com/prayer-times-api).

Example API call:
```
https://api.aladhan.com/v1/timingsByCity?city=Morgantown&state=WV&country=US&method=2
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available for personal and educational use.

## Acknowledgments

- Prayer times provided by [Aladhan API](https://aladhan.com)
- Developed for use on Raspberry Pi and Linux systems

## Support

For issues, questions, or suggestions, please open an issue on the [GitHub repository](https://github.com/MushfiqShovon/AthanClock).

---

**Made with ❤️ for the Muslim community**
