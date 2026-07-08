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

## Xcode Cloud → TestFlight

The `.xcodeproj` is generated (not committed), so Xcode Cloud regenerates it on every build via `IoniqOS/ci_scripts/ci_post_clone.sh` (installs XcodeGen, runs `xcodegen generate`). The shared `MedicationLock` scheme it needs is defined in `project.yml`.

### One-time Apple setup (do this first)

1. **Request the Family Controls *distribution* entitlement.** Development builds only need the capability, but TestFlight/App Store signing requires Apple's approval per bundle ID. Submit the request form at <https://developer.apple.com/contact/request/family-controls-distribution> for **all three** bundle IDs:
   - `com.mattgottfried.ioniqos`
   - `com.mattgottfried.ioniqos.monitor`
   - `com.mattgottfried.ioniqos.shield`

   Approval typically takes days to a few weeks. Until it's granted, archive builds will fail signing for TestFlight — everything else below can still be set up in the meantime.
2. In [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list), make sure the three App IDs exist with **Family Controls** and **App Groups** (`group.com.mattgottfried.ioniqos`) enabled.
3. In [App Store Connect](https://appstoreconnect.apple.com) → Apps → **+ New App**, create the app record with bundle ID `com.mattgottfried.ioniqos`.

### Create the workflow

1. Put your Team ID in `project.yml` (`DEVELOPMENT_TEAM`), run `xcodegen generate`, and open `MedicationLock.xcodeproj`.
2. In Xcode: **Integrate → Xcode Cloud → Create Workflow…** (or Product → Xcode Cloud). Select the `MedicationLock` product.
3. Grant Xcode Cloud access to the GitHub repo when prompted (it walks you through installing the Xcode Cloud GitHub app on `mattgottfried/medlock`).
4. Edit the workflow:
   - **Environment**: latest released Xcode, latest macOS.
   - **Start Conditions**: branch changes on your release branch (e.g. `main`).
   - **Actions**: **Archive — iOS**, with *TestFlight (Internal Testing Only)* as the deployment preparation.
   - **Post-Actions**: **TestFlight Internal Testing** → add your internal tester group.
5. Save and click **Start Build**. Xcode Cloud clones the repo, runs `ci_post_clone.sh` to generate the project, archives with cloud-managed signing, and uploads to TestFlight.

Notes:
- Xcode Cloud manages code signing automatically — no certificates or profiles to upload.
- Xcode Cloud auto-increments `CFBundleVersion` for TestFlight builds; you never bump it by hand. Bump `MARKETING_VERSION` in `project.yml` for user-facing releases.
- `ITSAppUsesNonExemptEncryption` is set to `false` in Info.plist, so builds skip the export-compliance questionnaire and become testable immediately.
- Install the TestFlight app on your iPhone and accept the tester invite emailed by App Store Connect.

---

## Limitations

1. **Simulator not supported** — Family Controls APIs are device-only.
2. **Not MDM-supervised** — a motivated user can disable Screen Time in Settings manually. This is intentional for personal use.
3. **Monitor extension runtime** — `intervalDidStart` gets ~5 seconds; keep it fast (it is).
4. **Location "Always" permission** must be granted in Settings → Privacy → Location Services for background geofencing to work.
5. **Shield primary button** opens `ioniqos://unlock` — iOS will open the main app, where the camera unlock flow lives.
