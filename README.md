# Weather && Stats

A KDE Plasma 6 **panel/taskbar widget** that displays live weather and system stats in a single compact bar. Designed to sit in your top or bottom panel — not a desktop widget.

![Plasma 6](https://img.shields.io/badge/Plasma-6.0+-blue) ![License](https://img.shields.io/badge/License-GPL--2.0-green)

## Overview

![Weather && Stats](weather-and-stats_example.png)


- **Weather** — current conditions via [Open-Meteo](https://open-meteo.com/) (no API key required)
- **CPU Temp** — reads directly from hwmon (Intel coretemp, AMD k10temp/zenpower, ARM cpu-thermal); turns red above your threshold
- **CPU Usage** — sampled from `/proc/stat`
- **Memory Usage** — percentage of RAM in use
- **Network Speed** — live download/upload on your most active interface

All stats update on configurable intervals. Each section can be toggled on or off.

## Requirements

- KDE Plasma 6.0+
- `bash`, `free`, `/proc/stat`, `/proc/net/dev` (standard on any Linux system)
- A [Nerd Font](https://www.nerdfonts.com/) set as your panel font is **optional** — the widget falls back to plain Unicode symbols if disabled in settings

## Installation

### Manual

```bash
git clone https://github.com/samjage/weather-and-stats.git
kpackagetool6 --type Plasma/Applet --install weather-and-stats
```

Then right-click your panel → **Add Widgets** → search for **Weather && Stats**.

> **Placement:** Plasma always adds new widgets at a default position. After adding, right-click your panel → **Enter Edit Mode** and drag the widget to your preferred spot (e.g. left of the system tray). Plasma has no API for widgets to declare a position automatically.

### To update after changes

```bash
kpackagetool6 --type Plasma/Applet --upgrade weather-and-stats
```

## Configuration

Right-click the widget → **Configure Weather && Stats**:

| Setting | Description | Default |
|---|---|---|
| Location | Search by city name (geocoded via Open-Meteo) | Chicago, IL |
| Temperature unit | °F or °C | °F |
| Show condition text | Adds e.g. "Partly Cloudy" after the temp | Off |
| Weather refresh | How often to fetch weather (minutes) | 5 min |
| CPU temp unit | °F or °C | °C |
| CPU temp alert threshold | Temp at which the reading turns red | 80°C |
| Stats refresh | How often to poll system stats (seconds) | 3 sec |
| Visible stats | Toggle CPU temp, CPU usage, memory, network | All on |
| Use Nerd Font icons | Use Nerd Font glyphs; disable for plain Unicode fallback | On |

## How it works

Weather is fetched with a plain `XMLHttpRequest` — no API key, no account needed. Open-Meteo is free for non-commercial use.

System stats come from a small shell script (`contents/stats.sh`) that the widget runs on a timer. It takes two `/proc/stat` samples 1 second apart to calculate CPU usage, and reads the same interface from `/proc/net/dev` for network throughput. No external dependencies.

## License

GPL-2.0 — see [LICENSE](LICENSE) if added, or the `metadata.json` for the declaration.
