# Athan Clock 🕌

Plays the Athan (call to prayer) at every prayer time for your city, automatically. Made for a home server, Raspberry Pi or any Linux machine that runs 24/7 and is connected to a speaker. Install it once with a single command, and it keeps running in the background, even after a restart.

🌐 **Website & easy installer: https://mushfiqshovon.github.io/AthanClock/**

## Features

- 🌍 Accurate daily prayer times for your location, from the [Aladhan API](https://aladhan.com/prayer-times-api)
- 🗺️ Pick your country, state and city on the website; your location is built into the install command
- 🔔 Plays the Athan at Dhuhr, Asr, Maghrib and Isha, each with its own recording (Fajr can be turned on)
- 🔊 Startup chime so you can hear that the app is running
- 🚀 One-command install and update
- 🔧 Runs in the background as a systemd user service and starts automatically on boot
- 💤 Handles sleep/suspend: an Athan missed while the machine was asleep is skipped instead of played late
- 📊 Built-in logging

## Requirements

- A machine that stays on **24/7** and has a **speaker connected** (HDMI, headphone jack, USB…)
- **Debian/Ubuntu-based Linux with systemd**, such as Raspberry Pi OS, Debian, Ubuntu or Linux Mint. The setup installs packages with `apt-get`.
- An internet connection (prayer times are fetched every day)

Tested on Raspberry Pi OS (Bookworm, desktop). Sound goes through the desktop audio server (PipeWire/PulseAudio) when there is one, so it plays on whatever output is selected as default.

## Installation

### Easiest: use the website

Go to **https://mushfiqshovon.github.io/AthanClock/**, pick your country, state and city from the lists, and copy the install command it builds for you. Paste it into a terminal and press Enter. Your location is included in the command, so there are no questions to answer.

### One command

Open a terminal and run (as your normal user, **not** with `sudo`; it asks for your password when needed):

```bash
curl -fsSL https://raw.githubusercontent.com/MushfiqShovon/AthanClock/main/install.sh | bash
```

This downloads the app into `~/AthanClock`, installs the required packages, asks for your location, and starts it as a background service that runs on every boot. When you hear the chime, it's running.

Only the files the app needs are downloaded; the website (`docs/`), `tools/` and this README are left out.

### Updating

Run the same install command again. It updates the app to the latest version and keeps your location settings.

### Manual install

```bash
git clone https://github.com/MushfiqShovon/AthanClock.git
cd AthanClock
./RunAthan.sh
```

`./RunAthan.sh` does the same setup as the one-command install. The service runs the app from the folder you cloned into, so don't move or delete that folder afterwards (if you do, run `./RunAthan.sh` again from the new location).

## Turning it off, on, or removing it

With the one-command install, the app lives in `~/AthanClock`:

| To… | Run |
|---|---|
| Pause it until the next restart | `~/AthanClock/RunAthan.sh stop` |
| Turn it off completely (keeps settings) | `~/AthanClock/RunAthan.sh stop && ~/AthanClock/RunAthan.sh disable-startup` |
| Turn it back on | `~/AthanClock/RunAthan.sh enable-startup && ~/AthanClock/RunAthan.sh start` |
| Change location | `~/AthanClock/RunAthan.sh configure` |
| Check that it's running | `~/AthanClock/RunAthan.sh status; ~/AthanClock/RunAthan.sh logs` |
| Uninstall | `~/AthanClock/RunAthan.sh uninstall && rm -rf ~/AthanClock` |

## Configuration

### Location

Your location is stored in `config.json` in the app folder. It's created by the website's install command or by answering the setup questions, and it isn't tracked by git, so updates never overwrite it.

To change it, run `~/AthanClock/RunAthan.sh configure` (it shows today's prayer times so you can check them), or run a new install command from the website. You can also edit the file directly and run `~/AthanClock/RunAthan.sh restart`:

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

- `latitude`/`longitude` are optional (the website fills them in). With them, times are looked up by coordinates, which is the most reliable. Without them, times are looked up by city and country name.
- `state` is optional. If a lookup with the state fails, the app automatically retries without it.
- Without a `config.json`, the defaults at the top of `prayer_clock.py` are used (Morgantown, WV, US, method 2).

### Calculation method

`method` sets how prayer times are calculated. The website picks the usual method for your country; choose a different one if your local mosque uses it. Common methods:

- `1` - University of Islamic Sciences, Karachi
- `2` - Islamic Society of North America (ISNA)
- `3` - Muslim World League
- `4` - Umm Al-Qura University, Makkah
- `5` - Egyptian General Authority of Survey

Full list: [Aladhan calculation methods](https://api.aladhan.com/v1/methods)

### Audio files

| File | Played for |
|---|---|
| `athan_durd.mp3` | Dhuhr, Asr and Maghrib |
| `athan_esha.mp3` | Isha |
| `athan_fajr.mp3` | Fajr (off by default) |
| `startup.mp3` | Short chime when the app starts |

You can replace any of them with your own mp3 of the same name.

**To turn on the Fajr Athan:** open `prayer_clock.py`, remove the `#` in front of the `"Fajr"` line in `ATHAN_FILES`, save, and run `./RunAthan.sh restart`.

### Other settings

At the top of `prayer_clock.py`:

```python
PLAYER = "mpg123 -q"          # Audio player command
LATE_LIMIT_MINUTES = 10       # Skip an Athan that is this late (e.g. the machine was asleep)
```

After changing anything, apply it with `./RunAthan.sh restart`.

## RunAthan.sh commands

Run from the app folder (`~/AthanClock` with the one-command install):

```bash
./RunAthan.sh [command]
```

| Command | What it does |
|---|---|
| *(no command)* or `setup` | Full setup: install packages, ask for location (first time only), enable on boot, start |
| `install` | Install the required packages only |
| `configure` | Set your city, country and calculation method |
| `start` / `stop` / `restart` | Start, stop or restart the app |
| `status` | Show whether the app is running |
| `logs` | Show the last 50 log lines |
| `enable-startup` / `disable-startup` | Turn starting on boot on or off |
| `uninstall` | Stop the app and remove its background service |

**Setup with a location, skipping the questions** (this is what the website's command does):

```bash
./RunAthan.sh setup --city 'Morgantown' --state 'West Virginia' --country 'United States' \
                    --method 2 --lat 39.6295 --lon -79.9559
```

`--state`, `--method`, `--lat` and `--lon` are optional.

To run the app in the foreground for testing, stop the service first so the Athan doesn't play twice:

```bash
./RunAthan.sh stop
python3 prayer_clock.py
```

## How It Works

1. **Fetches prayer times** for today from the Aladhan API, by coordinates when `config.json` has them, otherwise by city name.
2. **Waits** until each prayer time, checking the real clock every 30 seconds so it stays on time even after the machine sleeps.
3. **Plays the Athan** with `mpg123`. An Athan more than 10 minutes late (for example, the machine was asleep) is skipped.
4. **Fetches new times** just after midnight, or right away after waking from a long sleep.
5. **Runs as a systemd user service** (`~/.config/systemd/user/prayerclock.service`) so it can use your audio. A system-wide service or cron job can't reach the desktop audio server, which results in no sound. "Linger" is enabled so the service starts at boot, even before anyone logs in, and systemd restarts it if it ever crashes.

Everything the app prints goes to `prayerclock.log` in the app folder. You can also use systemd directly: `systemctl --user status prayerclock`.

## Troubleshooting

### Check that it's running

```bash
./RunAthan.sh status
./RunAthan.sh logs
```

After each start, the log should show:

```
Athan Application is started. Playing startup sound...
Startup sound played OK.
Location: Morgantown, West Virginia, United States (39.6295, -79.9559) (method 2)
? Waiting 41 minutes for Isha at 20:24
```

### No sound

- Check that the right output (HDMI / headphone jack) is selected as default in the desktop volume menu, then run `./RunAthan.sh restart`. You should hear the chime.
- Test the speaker directly: `mpg123 startup.mp3`
- `Startup sound FAILED` in the log means mpg123 couldn't play audio.
- On a machine without a desktop (e.g. a server install), your user may need to be in the `audio` group: `sudo usermod -aG audio $USER`, then reboot.
- If you set up an older version of this app (as a system service or from crontab), run `./RunAthan.sh` again; it removes the old setup.

### Prayer times can't be fetched

- Right after boot, one `Could not connect to Aladhan API` message is normal while the network comes up. The app retries every 2 minutes.
- Check the internet connection.
- Check your location with `./RunAthan.sh configure` (it shows today's times for what you enter), or pick your city on the website, which uses coordinates.

### Times are off by an hour or more

The machine's clock must be set to the time zone of your location. Check with `timedatectl`, and change it with `sudo timedatectl set-timezone Your/Zone` (for example `America/New_York`).

### Permission denied

```bash
chmod +x RunAthan.sh
```

## Project Structure

| Path | Purpose |
|---|---|
| `prayer_clock.py` | The app: fetches times and plays the Athan |
| `RunAthan.sh` | Setup and service manager |
| `install.sh` | One-command installer (downloads the app and runs setup) |
| `*.mp3` | Athan recordings and the startup chime |
| `docs/` | Website, served by GitHub Pages (not downloaded by the installer) |
| `tools/build_location_data.py` | Builds the website's Country → State → City lists |

## Dependencies

- **python3** and **python3-requests** - run the app and call the prayer times API
- **mpg123** - plays the mp3 files

All of them are installed automatically by the setup.

## API Reference

Prayer times come from the [Aladhan Prayer Times API](https://aladhan.com/prayer-times-api). Example calls:

```
# By coordinates (used when config.json has latitude/longitude)
https://api.aladhan.com/v1/timings/27-09-2026?latitude=39.6295&longitude=-79.9559&method=2

# By city name
https://api.aladhan.com/v1/timingsByCity?city=Morgantown&state=WV&country=US&method=2
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available for personal and educational use.

## Acknowledgments

- Prayer times provided by [Aladhan](https://aladhan.com)
- Place data © [GeoNames](https://www.geonames.org/), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)

## Support

For issues, questions, or suggestions, please open an issue on the [GitHub repository](https://github.com/MushfiqShovon/AthanClock).

---

**Made with ❤️ for the Muslim community**
