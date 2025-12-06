import requests
import datetime
import time
import os
    
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# ========= CONFIG =========
CITY = "Morgantown"
COUNTRY = "USA"
METHOD = 2  # Muslim World League calculation method
ATHAN_FILES = {
    "Fajr": os.path.join(SCRIPT_DIR, "athan_fajr.mp3"),
    "Isha": os.path.join(SCRIPT_DIR, "athan_esha.mp3"),
    "Dhuhr": os.path.join(SCRIPT_DIR, "athan_durd.mp3"),
    "Asr": os.path.join(SCRIPT_DIR, "athan_durd.mp3"),
    "Maghrib": os.path.join(SCRIPT_DIR, "athan_durd.mp3")
}

PLAYER = "mpg123"  # Change to 'aplay' if using .wav
# ==========================

def get_prayer_times():
    """Fetch today's prayer times from Aladhan API."""
    url = f"http://api.aladhan.com/v1/timingsByCity?city={CITY}&country={COUNTRY}&method={METHOD}"
    try:
        response = requests.get(url, timeout=10)
        data = response.json()
        timings = data['data']['timings']
        return timings
    except Exception as e:
        print("? Error fetching prayer times:", e)
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

def play_athan(prayer_name):
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
    os.system('espeak "Athan Application is started."')
    #play_athan("Fajr") # for sound testing
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
                play_athan(name)

        # Sleep until just after midnight before re-fetching
        tomorrow = datetime.datetime.combine(datetime.date.today() + datetime.timedelta(days=1),
                                             datetime.time(0, 5))
        wait_tomorrow = (tomorrow - datetime.datetime.now()).total_seconds()
        print("? Done for today. Sleeping until tomorrow...")
        # os.system('espeak "Done for today. Sleeping until tomorrow."')
        time.sleep(wait_tomorrow)

if __name__ == "__main__":
    main()
