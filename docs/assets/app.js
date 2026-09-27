// Athan Clock website: location picker, prayer time preview and install command builder.
(function () {
  "use strict";

  const REPO = "MushfiqShovon/AthanClock";
  const BRANCH = "main";
  const INSTALL_URL = `https://raw.githubusercontent.com/${REPO}/${BRANCH}/install.sh`;
  const BASE_COMMAND = `curl -fsSL ${INSTALL_URL} | bash`;

  // Aladhan calculation methods (https://api.aladhan.com/v1/methods)
  const METHODS = [
    [1, "University of Islamic Sciences, Karachi"],
    [2, "Islamic Society of North America (ISNA)"],
    [3, "Muslim World League"],
    [4, "Umm Al-Qura University, Makkah"],
    [5, "Egyptian General Authority of Survey"],
    [7, "Institute of Geophysics, University of Tehran"],
    [8, "Gulf Region"],
    [9, "Kuwait"],
    [10, "Qatar"],
    [11, "Majlis Ugama Islam Singapura, Singapore"],
    [12, "Union Organization Islamic de France"],
    [13, "Diyanet İşleri Başkanlığı, Turkey"],
    [14, "Spiritual Administration of Muslims of Russia"],
    [15, "Moonsighting Committee Worldwide"],
    [16, "Dubai"],
    [17, "JAKIM, Malaysia"],
    [18, "Tunisia"],
    [19, "Algeria"],
    [20, "Kementerian Agama, Indonesia"],
    [21, "Morocco"],
    [22, "Comunidade Islamica de Lisboa"],
    [23, "Ministry of Awqaf, Jordan"],
    [0, "Shia Ithna-Ashari, Leva Institute, Qum"],
  ];
  const PRAYERS = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"];

  const $ = (id) => document.getElementById(id);
  const els = {
    country: $("country"),
    state: $("state"),
    city: $("city"),
    method: $("method"),
    manualToggle: $("manual-toggle"),
    manual: $("manual"),
    manualCity: $("manual-city"),
    preview: $("preview"),
    previewPlace: $("preview-place"),
    previewTimes: $("preview-times"),
    previewNote: $("preview-note"),
    command: $("install-command"),
    commandHint: $("command-hint"),
    copyInstall: $("copy-install"),
    downloadConfig: $("download-config"),
    toast: $("toast"),
  };

  let countries = [];
  let states = []; // [[stateName, [[city, lat, lon], ...]], ...] for the selected country
  const countryCache = {};

  // ---------- helpers ----------

  function option(value, label) {
    const o = document.createElement("option");
    o.value = value;
    o.textContent = label;
    return o;
  }

  function fillSelect(select, placeholder, items) {
    select.replaceChildren(option("", placeholder), ...items);
    select.disabled = items.length === 0;
  }

  // Quote a value for bash: wrap in single quotes, escaping any single quotes inside
  function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
  }

  let toastTimer;
  function toast(message) {
    els.toast.textContent = message;
    els.toast.classList.add("show");
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => els.toast.classList.remove("show"), 2200);
  }

  async function copyText(text) {
    try {
      await navigator.clipboard.writeText(text);
    } catch (e) {
      // Fallback for browsers/pages without clipboard API access
      const ta = document.createElement("textarea");
      ta.value = text;
      ta.setAttribute("readonly", "");
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      document.execCommand("copy");
      ta.remove();
    }
    toast("Copied! Paste it into a terminal.");
  }

  // ---------- current selection ----------

  function selectedCountry() {
    return countries.find((c) => c.code === els.country.value) || null;
  }

  function selectedCityData() {
    const st = states[Number(els.state.value)];
    if (!st || els.city.value === "") return null;
    return st[1][Number(els.city.value)];
  }

  // Returns the settings for config.json, or null while the selection is incomplete
  function currentConfig() {
    const country = selectedCountry();
    if (!country) return null;
    const method = Number(els.method.value);

    if (els.manualToggle.checked) {
      const city = els.manualCity.value.trim();
      if (!city) return null;
      return { city, state: "", country: country.name, method };
    }

    const cityData = selectedCityData();
    if (!cityData) return null;
    const stateName = states[Number(els.state.value)][0];
    return {
      city: cityData[0],
      state: stateName === "Other" ? "" : stateName,
      country: country.name,
      method,
      latitude: cityData[1],
      longitude: cityData[2],
    };
  }

  // ---------- output: command, download, preview ----------

  function buildCommand(cfg) {
    if (!cfg) return BASE_COMMAND;
    const args = ["--city", shellQuote(cfg.city)];
    if (cfg.state) args.push("--state", shellQuote(cfg.state));
    args.push("--country", shellQuote(cfg.country), "--method", String(cfg.method));
    if (cfg.latitude !== undefined) {
      args.push("--lat", String(cfg.latitude), "--lon", String(cfg.longitude));
    }
    return `${BASE_COMMAND} -s -- ${args.join(" ")}`;
  }

  function update() {
    const cfg = currentConfig();
    els.command.textContent = buildCommand(cfg);
    els.downloadConfig.disabled = !cfg;
    els.commandHint.textContent = cfg
      ? `Your location (${[cfg.city, cfg.state, cfg.country].filter(Boolean).join(", ")}) is built into this command.`
      : "Choose your location above and your settings will be built into the command. You can also copy it now and answer the questions in the terminal instead.";
    schedulePreview(cfg);
  }

  let previewTimer;
  let previewRequest = 0;
  function schedulePreview(cfg) {
    clearTimeout(previewTimer);
    previewRequest++; // ignore any response still on its way for the old selection
    els.previewTimes.replaceChildren();
    if (!cfg) {
      els.preview.hidden = true;
      return;
    }
    els.preview.hidden = false;
    els.previewPlace.textContent = [cfg.city, cfg.state, cfg.country].filter(Boolean).join(", ");
    els.previewNote.textContent = "Loading…";
    previewTimer = setTimeout(() => loadPreview(cfg), 350);
  }

  async function loadPreview(cfg) {
    const request = ++previewRequest;

    let url;
    if (cfg.latitude !== undefined) {
      const d = new Date();
      const date = `${String(d.getDate()).padStart(2, "0")}-${String(d.getMonth() + 1).padStart(2, "0")}-${d.getFullYear()}`;
      url = `https://api.aladhan.com/v1/timings/${date}?latitude=${cfg.latitude}&longitude=${cfg.longitude}&method=${cfg.method}`;
    } else {
      const params = new URLSearchParams({ city: cfg.city, country: cfg.country, method: cfg.method });
      if (cfg.state) params.set("state", cfg.state);
      url = `https://api.aladhan.com/v1/timingsByCity?${params}`;
    }

    try {
      const res = await fetch(url);
      const json = await res.json();
      if (request !== previewRequest) return; // a newer selection is loading
      if (json.code !== 200 || !json.data || !json.data.timings) throw new Error("bad response");
      const t = json.data.timings;
      els.previewTimes.replaceChildren(
        ...PRAYERS.map((name) => {
          const div = document.createElement("div");
          div.className = "time";
          const label = document.createElement("span");
          label.textContent = name;
          const value = document.createElement("strong");
          value.textContent = String(t[name]).slice(0, 5);
          div.append(label, value);
          return div;
        })
      );
      const tz = json.data.meta && json.data.meta.timezone;
      els.previewNote.textContent = tz
        ? `Times are in the ${tz} time zone. Your computer's clock should be set to this time zone too.`
        : "";
    } catch (e) {
      if (request !== previewRequest) return;
      els.previewNote.textContent = els.manualToggle.checked
        ? "Couldn't find times for this city name. Check the spelling, or pick a nearby city from the list."
        : "Couldn't load a preview right now. The install command will still work.";
    }
  }

  function downloadConfig() {
    const cfg = currentConfig();
    if (!cfg) return;
    const blob = new Blob([JSON.stringify(cfg, null, 2) + "\n"], { type: "application/json" });
    const a = document.createElement("a");
    a.href = URL.createObjectURL(blob);
    a.download = "config.json";
    document.body.appendChild(a);
    a.click();
    a.remove();
    setTimeout(() => URL.revokeObjectURL(a.href), 1000);
  }

  // ---------- dropdown loading ----------

  async function onCountryChange() {
    const country = selectedCountry();
    fillSelect(els.state, country ? "Loading…" : "Select a country first", []);
    fillSelect(els.city, "Select a state first", []);
    states = [];
    update();
    if (!country) return;

    els.method.value = String(country.method);
    try {
      if (!countryCache[country.code]) {
        const res = await fetch(`data/${country.code}.json`);
        if (!res.ok) throw new Error(res.status);
        countryCache[country.code] = await res.json();
      }
    } catch (e) {
      fillSelect(els.state, "Couldn't load states", []);
      return;
    }
    if (els.country.value !== country.code) return; // changed while loading
    states = countryCache[country.code];
    fillSelect(els.state, "Select a state / region", states.map((s, i) => option(i, s[0])));
    if (states.length === 1) {
      els.state.value = "0";
      onStateChange();
    }
    update();
  }

  function onStateChange() {
    const st = states[Number(els.state.value)];
    if (els.state.value === "" || !st) {
      fillSelect(els.city, "Select a state first", []);
    } else {
      fillSelect(els.city, `Select a city (${st[1].length})`, st[1].map((c, i) => option(i, c[0])));
    }
    update();
  }

  function onManualToggle() {
    els.manual.hidden = !els.manualToggle.checked;
    els.city.disabled = els.manualToggle.checked || els.city.options.length <= 1;
    if (els.manualToggle.checked) els.manualCity.focus();
    update();
  }

  async function init() {
    els.method.replaceChildren(...METHODS.map(([id, name]) => option(id, `${id} · ${name}`)));
    els.method.value = "3";
    els.command.textContent = BASE_COMMAND;

    els.country.addEventListener("change", onCountryChange);
    els.state.addEventListener("change", onStateChange);
    els.city.addEventListener("change", update);
    els.method.addEventListener("change", update);
    els.manualToggle.addEventListener("change", onManualToggle);
    els.manualCity.addEventListener("input", update);
    els.copyInstall.addEventListener("click", () => copyText(els.command.textContent));
    els.downloadConfig.addEventListener("click", downloadConfig);
    document.querySelectorAll(".command .copy").forEach((btn) => {
      btn.addEventListener("click", () => copyText(btn.previousElementSibling.textContent));
    });

    try {
      const res = await fetch("data/countries.json");
      countries = await res.json();
    } catch (e) {
      fillSelect(els.country, "Couldn't load countries", []);
      return;
    }
    fillSelect(els.country, "Select a country", countries.map((c) => option(c.code, c.name)));

    // Preselect the visitor's country from the browser language (e.g. "en-US" -> US)
    const region = (navigator.language || "").split("-")[1];
    if (region && countries.some((c) => c.code === region.toUpperCase())) {
      els.country.value = region.toUpperCase();
      onCountryChange();
    }
  }

  init();
})();
