#!/usr/bin/env python3
import requests
import datetime
import time
import os
import json

# Get absolute path of the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# ========= CONFIG =========
# Location defaults; config.json (created by "./RunAthan.sh configure") overrides these
CITY = "Morgantown"
STATE = "WV"
COUNTRY = "US"
METHOD = 2  # ISNA calculation method (3 = Muslim World League)
LATE_LIMIT_MINUTES = 10  # Skip an Athan that is this late (e.g. computer was asleep)
#ATHAN_FILE = "~/athan/athan_fajr.mp3"  # Path to your Athan file
ATHAN_FILES = {
    #"Fajr": os.path.join(SCRIPT_DIR, "athan_fajr.mp3"),
    "Isha": os.path.join(SCRIPT_DIR, "athan_esha.mp3"),
    "Dhuhr": os.path.join(SCRIPT_DIR, "athan_durd.mp3"),
    "Asr": os.path.join(SCRIPT_DIR, "athan_durd.mp3"),
    "Maghrib": os.path.join(SCRIPT_DIR, "athan_durd.mp3")
}
STARTUP_SOUND = os.path.join(SCRIPT_DIR, "startup.mp3")  # Played once when the app starts

#PLAYER = "mpg123"  # Change to 'aplay' if using .wav
PLAYER = "mpg123 -q"  # plays through the default PipeWire/PulseAudio output
# ==========================

CONFIG_FILE = os.path.join(SCRIPT_DIR, "config.json")
if os.path.exists(CONFIG_FILE):
    with open(CONFIG_FILE) as f:
        _config = json.load(f)
    CITY = _config.get("city", CITY)
    STATE = _config.get("state", STATE)
    COUNTRY = _config.get("country", COUNTRY)
    METHOD = int(_config.get("method", METHOD))

def get_prayer_times():
    """Fetch today's prayer times from Aladhan API."""

    url = "https://api.aladhan.com/v1/timingsByCity"

    params = {
        "city": CITY,
        "country": COUNTRY,
        "method": METHOD
    }
    if STATE:  # An empty state makes the API's location lookup fail
        params["state"] = STATE

    try:
        response = requests.get(url, params=params, timeout=10)

        if response.status_code == 503:
            print("Aladhan server is temporarily unavailable (503).")
            return None

        response.raise_for_status()

        data = response.json()

        if data.get("code") != 200:
            print("Aladhan API error:")
            print(data)
            return None

        api_data = data.get("data")

        if not isinstance(api_data, dict):
            print("Unexpected API response:")
            print(data)
            return None

        timings = api_data.get("timings")

        if not isinstance(timings, dict):
            print("Prayer timings missing:")
            print(data)
            return None

        return timings

    except requests.exceptions.Timeout:
        print("Aladhan API request timed out.")
        return None

    except requests.exceptions.ConnectionError:
        print("Could not connect to Aladhan API.")
        return None

    except requests.exceptions.RequestException as e:
        print("Network/API error:", e)
        return None

    except ValueError as e:
        print("Invalid JSON response:", e)
        return None
        
        
def parse_times(timings):
    """Convert timings to datetime objects for today."""
    today = datetime.date.today()
    prayer_names = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    prayer_times = []

    for name in prayer_names:
        t = timings[name]
        hour, minute = map(int, t.split(":"))
        dt = datetime.datetime.combine(today, datetime.time(hour, minute))
        prayer_times.append((name, dt))
    return prayer_times

#def play_athan():
#    """Play the Athan sound file."""
#    print(ATHAN_FILE)
#    os.system(f"{PLAYER} {ATHAN_FILE}")

def play_athan_var(prayer_name):
    """Play the correct Athan sound file based on prayer name."""
    print(prayer_name)
    athan_file = ATHAN_FILES.get(prayer_name)
    if athan_file:
        athan_file = os.path.expanduser(athan_file)  # expand ~ to /home/pi
        print(f"Playing: {athan_file}")
        if os.path.exists(athan_file):
            os.system(f"{PLAYER} '{athan_file}'")
        else:
            print(f"? File not found: {athan_file}")
    else:
        print(f"?? No Athan file found for {prayer_name}")

def sleep_until(target):
    """Sleep until the wall clock reaches target.

    Sleeps in short steps and re-checks the real time, because time.sleep()
    does not count time spent in suspend; one long sleep would wake up late.
    """
    while True:
        remaining = (target - datetime.datetime.now()).total_seconds()
        if remaining <= 0:
            return
        time.sleep(min(remaining, 30))

def main():
    print("Athan Application is started. Playing startup sound...")
    status = os.system(f"{PLAYER} '{STARTUP_SOUND}'")
    print("Startup sound played OK." if status == 0 else f"Startup sound FAILED (exit status {status}).")
    print(f"Location: {CITY}, {STATE}, {COUNTRY} (method {METHOD})")
    #play_athan_var("Fajr")
    while True:
        fetch_date = datetime.date.today()
        timings = get_prayer_times()
        if not timings:
            print("?? Failed to fetch times, retrying in 2 mins...")
            time.sleep(120)
            continue

        prayer_times = parse_times(timings)

        for name, pt in prayer_times:
            now = datetime.datetime.now()
            wait = (pt - now).total_seconds()

            if wait > 0:
                print(f"? Waiting {int(wait/60)} minutes for {name} at {pt.strftime('%H:%M')}")
                sleep_until(pt)
                late = (datetime.datetime.now() - pt).total_seconds() / 60
                if late > LATE_LIMIT_MINUTES:
                    print(f"? Skipping {name}: woke up {int(late)} minutes late (was the computer asleep?)")
                    continue
                print(f"? {name} time! Playing Athan...")
                play_athan_var(name)

        # Sleep until just after midnight before re-fetching. Based on the day the
        # times were fetched, so waking from a long suspend re-fetches right away.
        tomorrow = datetime.datetime.combine(fetch_date + datetime.timedelta(days=1),
                                             datetime.time(0, 5))
        print("? Done for today. Sleeping until tomorrow...")
        sleep_until(tomorrow)

if __name__ == "__main__":
    main()
