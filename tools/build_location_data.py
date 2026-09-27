#!/usr/bin/env python3
"""Build the Country -> State -> City data used by the website (docs/data/).

Source: GeoNames (https://www.geonames.org/), licensed CC BY 4.0.
Uses every place with a population of 5000 or more.

Usage:
    python3 tools/build_location_data.py            # downloads GeoNames files
    python3 tools/build_location_data.py GEO_DIR    # uses files already in GEO_DIR
"""
import io
import json
import os
import sys
import tempfile
import urllib.request
import zipfile

BASE_URL = "https://download.geonames.org/export/dump/"
OUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "data")

# Suggested Aladhan calculation method per country (the user can still change it)
METHOD_BY_COUNTRY = {
    "US": 2, "CA": 2,
    "PK": 1, "IN": 1, "BD": 1, "AF": 1,
    "SA": 4, "YE": 4,
    "EG": 5, "SD": 5, "SY": 5, "LB": 5, "IQ": 5, "LY": 5, "MY": 17,
    "AE": 8, "OM": 8, "BH": 8, "KW": 9, "QA": 10, "SG": 11, "FR": 12, "TR": 13, "RU": 14,
    "IR": 7, "JO": 23, "DZ": 19, "TN": 18, "MA": 21, "ID": 20, "PT": 22,
}
DEFAULT_METHOD = 3  # Muslim World League


def read_text(geo_dir, name):
    if geo_dir:
        with open(os.path.join(geo_dir, name), encoding="utf-8") as f:
            return f.read()
    print(f"Downloading {name}...")
    with urllib.request.urlopen(BASE_URL + name) as r:
        data = r.read()
    if name.endswith(".zip"):
        with zipfile.ZipFile(io.BytesIO(data)) as z:
            return z.read(name.replace(".zip", ".txt")).decode("utf-8")
    return data.decode("utf-8")


def main():
    geo_dir = sys.argv[1] if len(sys.argv) > 1 else None
    if geo_dir and not os.path.exists(os.path.join(geo_dir, "cities5000.txt")):
        with zipfile.ZipFile(os.path.join(geo_dir, "cities5000.zip")) as z:
            z.extractall(geo_dir)

    countries = {}
    for line in read_text(geo_dir, "countryInfo.txt").splitlines():
        if line.startswith("#") or not line.strip():
            continue
        cols = line.split("\t")
        countries[cols[0]] = cols[4]

    states = {}
    for line in read_text(geo_dir, "admin1CodesASCII.txt").splitlines():
        cols = line.split("\t")
        states[cols[0]] = cols[1]

    cities_txt = "cities5000.txt" if geo_dir else "cities5000.zip"
    # country -> state -> city name -> (population, lat, lon)
    tree = {}
    for line in read_text(geo_dir, cities_txt).splitlines():
        cols = line.split("\t")
        name, lat, lon, cc, admin1, pop = cols[1], cols[4], cols[5], cols[8], cols[10], cols[14]
        if cc not in countries:
            continue
        state = states.get(f"{cc}.{admin1}", "Other")
        pop = int(pop or 0)
        cities = tree.setdefault(cc, {}).setdefault(state, {})
        # Keep the largest place when a state has two places with the same name
        if name not in cities or pop > cities[name][0]:
            cities[name] = (pop, round(float(lat), 4), round(float(lon), 4))

    os.makedirs(OUT_DIR, exist_ok=True)
    for old in os.listdir(OUT_DIR):
        if old.endswith(".json"):
            os.remove(os.path.join(OUT_DIR, old))

    index = []
    for cc, state_map in tree.items():
        out = [
            [state, [[city, lat, lon] for city, (_, lat, lon) in sorted(cities.items())]]
            for state, cities in sorted(state_map.items(), key=lambda s: (s[0] == "Other", s[0]))
        ]
        with open(os.path.join(OUT_DIR, f"{cc}.json"), "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, separators=(",", ":"))
        index.append({"code": cc, "name": countries[cc],
                      "method": METHOD_BY_COUNTRY.get(cc, DEFAULT_METHOD)})

    index.sort(key=lambda c: c["name"])
    with open(os.path.join(OUT_DIR, "countries.json"), "w", encoding="utf-8") as f:
        json.dump(index, f, ensure_ascii=False, separators=(",", ":"))
    total = sum(len(c) for s in tree.values() for c in s.values())
    print(f"Wrote {len(index)} countries and {total} cities to {os.path.normpath(OUT_DIR)}")


if __name__ == "__main__":
    main()
