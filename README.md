# Weather && Stats

A KDE Plasma 6 panel widget that displays live weather and system stats in a single compact bar.

![Plasma 6](https://img.shields.io/badge/Plasma-6.0+-blue) ![License](https://img.shields.io/badge/License-GPL--2.0-green)

## Overview

![Weather && Stats](https://private-user-images.githubusercontent.com/11218296/567482167-00d58726-ac7e-4cfd-94d5-1276a7345bf9.png?jwt=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpc3MiOiJnaXRodWIuY29tIiwiYXVkIjoicmF3LmdpdGh1YnVzZXJjb250ZW50LmNvbSIsImtleSI6ImtleTUiLCJleHAiOjE3NzQyMjg1OTAsIm5iZiI6MTc3NDIyODI5MCwicGF0aCI6Ii8xMTIxODI5Ni81Njc0ODIxNjctMDBkNTg3MjYtYWM3ZS00Y2ZkLTk0ZDUtMTI3NmE3MzQ1YmY5LnBuZz9YLUFtei1BbGdvcml0aG09QVdTNC1ITUFDLVNIQTI1NiZYLUFtei1DcmVkZW50aWFsPUFLSUFWQ09EWUxTQTUzUFFLNFpBJTJGMjAyNjAzMjMlMkZ1cy1lYXN0LTElMkZzMyUyRmF3czRfcmVxdWVzdCZYLUFtei1EYXRlPTIwMjYwMzIzVDAxMTEzMFomWC1BbXotRXhwaXJlcz0zMDAmWC1BbXotU2lnbmF0dXJlPTliNzZjOTAzZmMxY2VmZDJlODc3YTNkMmQxODgzZTM4YTRhZDA1NTExZDUwMGMxZWM3ZmNjMTY5NTNjYTE0YmImWC1BbXotU2lnbmVkSGVhZGVycz1ob3N0In0.6pE1WkIcctxXsJMkG_mWTB5Lb99sbYYzRkZueInZ4qg)


- **Weather** — current conditions via [Open-Meteo](https://open-meteo.com/) (no API key required)
- **CPU Temp** — reads directly from hwmon (Intel coretemp, AMD k10temp/zenpower, ARM cpu-thermal); turns red above your threshold
- **CPU Usage** — sampled from `/proc/stat`
- **Memory Usage** — percentage of RAM in use
- **Network Speed** — live download/upload on your most active interface

All stats update on configurable intervals. Each section can be toggled on or off.

## Requirements

- KDE Plasma 6.0+
- A [Nerd Font](https://www.nerdfonts.com/) set as your panel font (for icons)
- `bash`, `free`, `/proc/stat`, `/proc/net/dev` (standard on any Linux system)

## Installation

### Manual

```bash
git clone https://github.com/samjage/weather-and-stats.git
kpackagetool6 --install weather-and-stats
```

Then right-click your panel → **Add Widgets** → search for **Weather && Stats**.

### To update after changes

```bash
kpackagetool6 --upgrade weather-and-stats
```

## Configuration

Right-click the widget → **Configure Weather && Stats**:

| Setting | Description | Default |
|---|---|---|
| Location | Search by city name (geocoded via Open-Meteo) | Canal Winchester, OH |
| Temperature unit | °F or °C | °F |
| Show condition text | Adds e.g. "Partly Cloudy" after the temp | Off |
| Weather refresh | How often to fetch weather (minutes) | 5 min |
| CPU temp unit | °F or °C | °C |
| CPU temp alert threshold | Temp at which the reading turns red | 80°C |
| Stats refresh | How often to poll system stats (seconds) | 3 sec |
| Visible stats | Toggle CPU temp, CPU usage, memory, network | All on |

## How it works

Weather is fetched with a plain `XMLHttpRequest` — no API key, no account needed. Open-Meteo is free for non-commercial use.

System stats come from a small shell script (`contents/stats.sh`) that the widget runs on a timer. It takes two `/proc/stat` samples 1 second apart to calculate CPU usage, and reads the same interface from `/proc/net/dev` for network throughput. No external dependencies.

## License

GPL-2.0 — see [LICENSE](LICENSE) if added, or the `metadata.json` for the declaration.
