# AMLEDS

**Autonomous Machine Latency Evaluation & Diagnostic System**

A network diagnostic tool for monitoring autonomous equipment with static IPs on Android. Built for field troubleshooting when you need a quick health check without lugging a laptop.

Think `mtr` or `ping` with a vintage terminal aesthetic and battery-friendly operation.

---

## What It Does

- **Ping monitoring** to multiple static IP endpoints simultaneously
- **Real-time vitals display** — current, average, and peak (with OL flatline indication like a DMM)
- **Rolling history chart** — last N readings with color-coded status
- **Machine profiles** — save equipment by name with multiple IPs (primary, backup, gateway, etc.)
- **Works offline** — no cloud, no accounts, no telemetry

Built for isolated industrial networks  where equipment has static addresses and you need quick triage.

---

## Status Colors

| Color | Meaning | Threshold |
|-------|---------|-----------|
| 🟢 Green | Excellent | < 30ms |
| 🟡 Yellow | Caution | 30–50ms |
| 🔴 Red | Critical / Flatline | ≥ 50ms or timeout |

---

## Screens

- **Machine List** — saved equipment, tap to monitor
- **Vitals Monitor** — real-time ping display with history charts
- **Add/Edit Machine** — name, equipment number, IP addresses
- **Settings** — thresholds, ping interval, history size

---

## Build

Prerequisites: Flutter SDK 3.0+, Android SDK API 21+

```bash
cd amleds
flutter pub get
flutter build apk --release
```

Install:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

---

## Technical Notes

- Uses system `/system/bin/ping` binary for reliable ICMP (no root required)
- Stores data locally in JSON (no cloud)
- Retro terminal theme — amber phosphor on dark grey, scanlines optional

---

## Copyright

© 2026 Shawn Baird

## License

This work is licensed under the **Creative Commons Attribution-NonCommercial 4.0 International License**.

You are free to:
- **Share** — copy and redistribute the material in any medium or format
- **Adapt** — remix, transform, and build upon the material

Under the following terms:
- **Attribution** — You must give appropriate credit
- **NonCommercial** — You may not use the material for commercial purposes

Full license text: https://creativecommons.org/licenses/by-nc/4.0/

---

*AMLEDS — field diagnostics for heavy machinery. Use at your own risk. Not a replacement for proper network analysis tools.*
