# FarmLens App — Phase 1

Edge AI Crop Health Monitoring — Flutter companion app for the FarmLens ESP32-S2 field node.

**Suez Canal University · Faculty of Engineering · IC EISIS 2026**
Abdel Rahman M. El-Saied · Mohamed Elsayed

---

## Setup

1. Install Flutter SDK (>=3.3.0)
2. Clone this repository
3. Run `flutter pub get`
4. Connect phone to the same WiFi as the ESP32 (`WE4ED705`)
5. Run `flutter run`
6. Enter ESP32 IP address: `192.168.1.22`
7. Port: `80`
8. Tap **Connect**

---

## File Structure

```
lib/
├── main.dart               — App entry point, MultiProvider setup
├── theme.dart              — FarmLensColors + farmLensTheme()
├── constants.dart          — IP, poll interval, timeout, pref keys
├── router.dart             — GoRouter: splash / connect / main / log/:id
├── utils/
│   └── formatters.dart     — formatDetectionClass, isDisease, ccombinedColor, timeAgo
├── models/
│   ├── live_data.dart      — LiveData.fromJson(), LiveData.empty()
│   ├── cycle_log.dart      — CycleLog.fromJson(), CycleLog.fromLiveData()
│   ├── node_status.dart    — NodeStatus.fromJson()
│   └── fusion_settings.dart — FusionSettings.fromJson(), toJson(), defaults()
├── services/
│   └── api_service.dart    — getStatus, getLive, getLogs, getSettings, postSettings
├── providers/
│   ├── settings_provider.dart    — deviceBaseUrl, fusionSettings, SharedPrefs
│   ├── connection_provider.dart  — DeviceConnectionState, connect(), disconnect()
│   ├── live_provider.dart        — polling loop, alerts list, unreadAlertCount
│   └── log_provider.dart         — cycles list, loadLogs(), addCycle()
└── screens/
    ├── splash_screen.dart        — 1s logo splash → redirect
    ├── connection_screen.dart    — IP/port form, recent IPs, connect flow
    ├── main_shell.dart           — IndexedStack + custom bottom nav
    ├── dashboard_screen.dart     — live gauge, sensor cards, detection, alert banner
    ├── alerts_screen.dart        — alert feed with red-border cards
    ├── log_screen.dart           — traceability log, shimmer, export, pull-to-refresh
    ├── log_detail_screen.dart    — full cycle detail, ETRACE badge
    └── settings_screen.dart      — sliders, crop chips, test connection, about
```

---

## API Contract

Device must serve these endpoints at `http://{ip}:80`:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/status` | Node health check — call on connect |
| GET | `/api/live` | Live sensor + detection data — polled every 5s |
| GET | `/api/logs?limit=50` | Traceability log entries |
| GET | `/api/settings` | Current fusion weights |
| POST | `/api/settings` | Update fusion weights |

**ESP32 Node:** IP `192.168.1.22` · Port `80` · WiFi `WE4ED705`

---

## Integration Test Checklist

Run these steps manually before TestFlight / Play Console submission.
Phone must be connected to `WE4ED705` WiFi (not mobile data).

- [ ] App launches with splash screen (logo + spinner, ~1 second)
- [ ] App connects to ESP32 at `192.168.1.22:80`
- [ ] Status screen shows `node_id: FL-001` and `mode: MOCK`
- [ ] Dashboard shows live moisture_pct and water_pct values
- [ ] Values update every 5 seconds (ESP32 sine wave drift visible)
- [ ] Ccombined gauge animates smoothly on value change
- [ ] Gauge color shifts: green (<0.4) → amber (0.4–0.65) → red (>0.65)
- [ ] Alert banner appears when `ccombined > theta` (default 0.5)
- [ ] Alert SnackBar fires at top of screen on new alert cycle
- [ ] Alerts tab shows alert history with red left-border cards
- [ ] Alert badge count shows on bottom nav Alerts tab
- [ ] Log tab loads cycle history with shimmer while loading
- [ ] Pull-to-refresh on Log tab reloads from device
- [ ] Export button triggers share sheet with JSON data
- [ ] Tap any log row → navigates to Log Detail screen
- [ ] Log Detail shows Detection / Sensors / Fusion / Traceability sections
- [ ] ETRACE badge visible at bottom of Log Detail
- [ ] Settings sliders post to ESP32 (`POST /api/settings`)
- [ ] Changing theta to 0.1 → alert fires on dashboard
- [ ] Restoring theta to 0.5 → alert clears
- [ ] Disconnect WiFi → app shows "Node offline" after 3 failed polls
- [ ] Reconnect WiFi → app recovers and resumes polling automatically
- [ ] "Test" button in Settings shows "Connected ✓" SnackBar

---

## Design System

| Token | Value |
|-------|-------|
| Primary green | `#1D9E75` |
| Amber / Watch | `#BA7517` |
| Alert / Red | `#E24B4A` |
| Background | `#F5F5F0` |
| Card | `#FFFFFF` |
| Text primary | `#1A1A1A` |
| Text secondary | `#6B7280` |
| Border | `#E8E8E4` |

Ccombined color rule: `< 0.4` green · `0.4–0.65` amber · `> 0.65` red

---

## Phase 2 Notes

| Phase 1 Limitation | Phase 2 Resolution |
|---|---|
| ESP32 mock data (no sensors) | RPi4 with real sensors + camera |
| `ts` field is uptime seconds | NTP sync → real UTC timestamps |
| Log buffer is RAM only | Persist to LittleFS / SD card |
| No detection images | RPi serves `/api/image/{id}` |
| Settings reset on reboot | Write to LittleFS flash |
| No authentication | API key header for production |