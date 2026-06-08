# IoniqOS — iPhone Medication Lockdown App

Forces a daily medication habit: at a configured time the iPhone shields selected apps via Apple's Screen Time / Family Controls API. The only way to remove the shield is to take a live camera photo of the medication bottle inside the app.

Location-awareness prevents the lock from firing when you're away from home — it queues and fires on arrival instead.

---

## Architecture

Three targets in one Xcode project:

| Target | Type | Purpose |
|---|---|---|
| `MedicationLock` | Application | Main SwiftUI app |
| `MedicationLockMonitor` | App Extension | `DeviceActivityMonitor` — fires at scheduled time |
| `MedicationLockShield` | App Extension | `ShieldConfiguration` — customises the lock overlay |

Shared state flows through an App Group (`group.com.mattgottfried.ioniqos`) in `UserDefaults`.

### State machine

```
unlocked ──[time fires + at home]──► locked
unlocked ──[time fires + away]──────► pendingHomeArrival
pendingHomeArrival ──[arrive home]──► locked
locked ──[camera photo taken]───────► unlocked
```

---

## Setup

### Prerequisites

1. **Apple Developer Program membership** (paid) — required for the `com.apple.developer.family-controls` entitlement.
2. Enable **Family Controls** capability in your App ID on [developer.apple.com](https://developer.apple.com/account/resources/identifiers/list).
3. Set your **Team ID** in `project.yml` under `settings.base.DEVELOPMENT_TEAM`.
4. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`

### Generate & open the project

```bash
cd IoniqOS
xcodegen generate
open MedicationLock.xcodeproj
```

### First launch (on a real device)

1. Run the app — it will request **Screen Time / Family Controls** permission (system alert, one-time).
2. Tap **Settings**, choose a lock time, select apps to block, and tap **Set Home to Current Location**.
3. Tap **Schedule Lock**.

---

## Testing

| Step | What to verify |
|---|---|
| Build | `xcodegen generate && open MedicationLock.xcodeproj` compiles clean on a real device |
| Family Controls | System sheet appears on first launch asking for Screen Time permission |
| Geofence | Set home, walk ~150 m away — `isAtHome` flips to `false` in the App Group container (Xcode → Devices → App Container) |
| Schedule | Set lock time 2 min from now; shields apply after timer fires |
| Pending flow | Manually set `isAtHome = false`, set lock time → confirm `lockPending = true` → simulate geofence entry → shields apply |
| Unlock | With shields active, open MedicationLock (not shielded), tap "Take Photo" — shields clear after capture |

---

## Limitations

1. **Simulator not supported** — Family Controls APIs are device-only.
2. **Not MDM-supervised** — a motivated user can disable Screen Time in Settings manually. This is intentional for personal use.
3. **Monitor extension runtime** — `intervalDidStart` gets ~5 seconds; keep it fast (it is).
4. **Location "Always" permission** must be granted in Settings → Privacy → Location Services for background geofencing to work.
5. **Shield primary button** opens `ioniqos://unlock` — iOS will open the main app, where the camera unlock flow lives.
