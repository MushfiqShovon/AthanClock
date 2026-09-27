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

- **Debian/Ubuntu-based Linux with systemd**, such as Raspberry Pi OS, Debian, Ubuntu or Linux Mint. The setup installs packages with `apt-get`.
- A working sound output. Sound is played through the desktop audio server (PipeWire/PulseAudio), so it goes to whatever output is selected as default.

Tested on Raspberry Pi OS (Bookworm, desktop). It also works on laptops and PCs that sleep: after waking up, the app catches up with the clock, and an Athan that was missed by more than 10 minutes is skipped instead of playing late.

## Installation

### Easiest: use the website

Go to **https://mushfiqshovon.github.io/AthanClock/**, pick your country, state and city from the lists, and copy the install command it builds for you. Your location is included in the command, so there are no questions to answer.

### Quick install (one command)

Open a terminal and run (as your normal user, **not** with `sudo`):

```bash
curl -fsSL https://raw.githubusercontent.com/MushfiqShovon/AthanClock/main/install.sh | bash
```

This downloads the app into `~/AthanClock`, installs everything, asks for your city, and starts it as a background service that runs on every boot. Running the same command again updates to the latest version and keeps your location settings. Only the files the app needs are downloaded; the website (`docs/`), `tools/` and this README are left out.

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
- Ask for your city, country and calculation method (first time only), and show today's prayer times so you can check them
- Create a systemd user service (`~/.config/systemd/user/prayerclock.service`)
- Enable it to start automatically on boot (using `loginctl enable-linger`)
- Start the app. You should hear the startup chime.

The service runs the app from the folder you cloned into, so don't move or delete that folder afterwards (if you do, run `./RunAthan.sh` again from the new location).

## Configuration

### Location

Setup asks for your location the first time. To change it later:

```bash
./RunAthan.sh configure
```

This saves your answers to `config.json` in the app folder (not tracked by git, so updates never overwrite it) and restarts the app. You can also edit `config.json` directly and run `./RunAthan.sh restart`:

```json
{
  "city": "Morgantown",
  "state": "West Virginia",
  "country": "United States",
  "method": 2,
  "latitude": 39.6295,
  "longitude": -79.9559
}
```

`latitude`/`longitude` are optional (the website fills them in). With them, times are looked up by coordinates; without them, by city and country name.

Without a `config.json`, the defaults at the top of `prayer_clock.py` are used (Morgantown, WV, US).

### Other settings

These are at the top of `prayer_clock.py`:

```python
PLAYER = "mpg123 -q"          # Audio player command
LATE_LIMIT_MINUTES = 10       # Skip an Athan that is this late (e.g. computer was asleep)
```

After changing them, apply with `./RunAthan.sh restart`.

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
- `configure` - Set your city/country and calculation method
- `start` - Start Athan Clock
- `stop` - Stop Athan Clock
- `restart` - Restart Athan Clock (use after editing the config)
- `status` - Check if Athan Clock is running
- `enable-startup` - Enable auto-start on system boot
- `disable-startup` - Remove from system startup
- `logs` - View the last 50 lines of application logs
- `uninstall` - Stop the app and remove its background service (then delete the folder to remove it completely)
- *(no command)* - Complete setup: install + enable startup + start

**Setup with a location, skipping the questions** (this is what the website's command does):
```bash
./RunAthan.sh setup --city 'Morgantown' --state 'West Virginia' --country 'United States' \
                    --method 2 --lat 39.6295 --lon -79.9559
```
`--state`, `--method`, `--lat` and `--lon` are optional. With `--lat`/`--lon`, prayer times are looked up by coordinates, which is the most reliable.

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
- Verify your location with `./RunAthan.sh configure` (it shows today's times for what you enter)
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

### Uninstall
```bash
./RunAthan.sh uninstall
rm -rf ~/AthanClock
```

## Website

The project website lives in the `docs/` folder and is served by GitHub Pages. It has no build step and uses no outside libraries.

- **Turn it on (once):** on GitHub, open the repo's **Settings → Pages**, set *Source* to **Deploy from a branch**, choose branch **main** and folder **/docs**, and save. After a minute or two it's live at `https://mushfiqshovon.github.io/AthanClock/`.
- **Preview locally:** `python3 -m http.server -d docs 8000`, then open http://localhost:8000
- **Location lists:** `docs/data/` holds one small file per country, built from [GeoNames](https://www.geonames.org/) (every place with 5,000+ people). To refresh it, run `python3 tools/build_location_data.py`.
- If you rename the repo or GitHub user, update `REPO` at the top of `docs/assets/app.js` and the links in `docs/index.html`.

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
