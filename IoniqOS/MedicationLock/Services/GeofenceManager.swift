import Foundation
import CoreLocation

final class GeofenceManager: NSObject {
    private let locationManager = CLLocationManager()
    private let appGroupID = "group.com.mattgottfried.ioniqos"
    private weak var appState: AppState?

    private var defaults: UserDefaults? { UserDefaults(suiteName: appGroupID) }

    init(appState: AppState) {
        self.appState = appState
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }

    func startIfAuthorized() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            setupHomeGeofenceIfNeeded()
        case .notDetermined:
            locationManager.requestAlwaysAuthorization()
        default:
            break
        }
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func setupHomeGeofence() {
        guard let location = locationManager.location else { return }
        let settings = AppSettings.load()
        var updated = settings
        updated.homeLatitude = location.coordinate.latitude
        updated.homeLongitude = location.coordinate.longitude
        updated.homeIsSet = true
        updated.save()
        appState?.settings = updated
        registerGeofence(lat: updated.homeLatitude, lon: updated.homeLongitude)
    }

    private func setupHomeGeofenceIfNeeded() {
        let settings = AppSettings.load()
        guard settings.homeIsSet else { return }
        registerGeofence(lat: settings.homeLatitude, lon: settings.homeLongitude)
    }

    private func registerGeofence(lat: Double, lon: Double) {
        locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = CLCircularRegion(center: center, radius: 100, identifier: "home")
        region.notifyOnEntry = true
        region.notifyOnExit = true
        locationManager.startMonitoring(for: region)
    }

    var currentLocation: CLLocation? { locationManager.location }
}

extension GeofenceManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
            setupHomeGeofenceIfNeeded()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        let settings = AppSettings.load()
        guard settings.homeIsSet else { return }

        let homeLocation = CLLocation(latitude: settings.homeLatitude, longitude: settings.homeLongitude)
        let isAtHome = location.distance(from: homeLocation) <= 100
        defaults?.set(isAtHome, forKey: "isAtHome")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier == "home" else { return }
        defaults?.set(true, forKey: "isAtHome")

        let isPending = defaults?.bool(forKey: "lockPending") ?? false
        if isPending {
            LockManager.shared.applyLock()
            DispatchQueue.main.async {
                self.appState?.setLockStatus(.locked)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard region.identifier == "home" else { return }
        defaults?.set(false, forKey: "isAtHome")
    }
}
