#!/usr/bin/env python3
import requests
import datetime
import time
import os
    
# Get absolute path of the directory where this script is located
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# ========= CONFIG =========
CITY = "Morgantown"
STATE = "WV"
COUNTRY = "US"
METHOD = 2  # ISNA calculation method (3 = Muslim World League)
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

def get_prayer_times():
    """Fetch today's prayer times from Aladhan API."""

    url = "https://api.aladhan.com/v1/timingsByCity"

    params = {
        "city": CITY,
        "state": STATE,
        "country": COUNTRY,
        "method": METHOD
    }

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

def main():
    print("Athan Application is started. Playing startup sound...")
    status = os.system(f"{PLAYER} '{STARTUP_SOUND}'")
    print("Startup sound played OK." if status == 0 else f"Startup sound FAILED (exit status {status}).")
    #play_athan_var("Fajr")
    while True:
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
                time.sleep(wait)
                print(f"? {name} time! Playing Athan...")
                play_athan_var(name)

        # Sleep until just after midnight before re-fetching
        tomorrow = datetime.datetime.combine(datetime.date.today() + datetime.timedelta(days=1),
                                             datetime.time(0, 5))
        wait_tomorrow = (tomorrow - datetime.datetime.now()).total_seconds()
        print("? Done for today. Sleeping until tomorrow...")
        # os.system('espeak "Done for today. Sleeping until tomorrow."')
        time.sleep(wait_tomorrow)

if __name__ == "__main__":
    main()
