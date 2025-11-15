import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    // Published properties for SwiftUI binding
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: String?
    @Published var isUpdatingLocation = false
    
    // Additional properties for better location handling
    @Published var lastKnownLocation: CLLocation?
    @Published var locationAccuracy: CLLocationAccuracy = 0
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    // MARK: - Setup
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update location every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    // MARK: - Public Methods
    
    /// Request location permission and start location updates
    func requestLocation() {
        clearError()
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            self.locationError = "Location access is denied. Please enable location access in Settings > Privacy & Security > Location Services."
        @unknown default:
            self.locationError = "Unknown authorization status"
        }
    }
    
    /// Start continuous location updates
    func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            requestLocation()
            return
        }
        
        isUpdatingLocation = true
        locationManager.startUpdatingLocation()
    }
    
    /// Stop location updates
    func stopLocationUpdates() {
        isUpdatingLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    /// Request a single location update
    func requestOneTimeLocation() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            requestLocation()
            return
        }
        
        isUpdatingLocation = true
        locationManager.requestLocation()
    }
    
    /// Clear any existing location error
    func clearError() {
        locationError = nil
    }
    
    /// Check if location services are available
    var isLocationServicesEnabled: Bool {
        return CLLocationManager.locationServicesEnabled()
    }
    
    /// Get distance between two coordinates
    func distance(from coordinate1: CLLocationCoordinate2D, to coordinate2: CLLocationCoordinate2D) -> CLLocationDistance {
        let location1 = CLLocation(latitude: coordinate1.latitude, longitude: coordinate1.longitude)
        let location2 = CLLocation(latitude: coordinate2.latitude, longitude: coordinate2.longitude)
        return location1.distance(from: location2)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            
            switch self.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.clearError()
                if self.isUpdatingLocation {
                    self.startLocationUpdates()
                }
            case .denied, .restricted:
                self.locationError = "Location access is denied. Please enable location access in Settings > Privacy & Security > Location Services."
                self.stopLocationUpdates()
            case .notDetermined:
                break
            @unknown default:
                self.locationError = "Unknown authorization status"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        DispatchQueue.main.async {
            // Filter out old or inaccurate locations
            if self.isLocationValid(newLocation) {
                self.location = newLocation
                self.lastKnownLocation = newLocation
                self.locationAccuracy = newLocation.horizontalAccuracy
                self.clearError()
                
                // Stop updating if we got a good accuracy
                if newLocation.horizontalAccuracy <= 100 {
                    self.stopLocationUpdates()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isUpdatingLocation = false
            
            if let clError = error as? CLError {
                switch clError.code {
                case .locationUnknown:
                    self.locationError = "Unable to determine location. Please try again."
                case .denied:
                    self.locationError = "Location access is denied. Please check your settings."
                case .network:
                    self.locationError = "Network error occurred while getting location."
                case .headingFailure:
                    self.locationError = "Unable to determine heading."
                case .regionMonitoringDenied, .regionMonitoringFailure:
                    self.locationError = "Region monitoring is not available."
                case .regionMonitoringSetupDelayed:
                    self.locationError = "Region monitoring setup is delayed."
                case .regionMonitoringResponseDelayed:
                    self.locationError = "Region monitoring response is delayed."
                case .geocodeFoundNoResult:
                    self.locationError = "No address found for the location."
                case .geocodeFoundPartialResult:
                    self.locationError = "Partial address found for the location."
                case .geocodeCanceled:
                    self.locationError = "Address lookup was canceled."
                @unknown default:
                    self.locationError = "Unknown location error occurred."
                }
            } else {
                self.locationError = "Unable to retrieve location: \(error.localizedDescription)"
            }
            
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func isLocationValid(_ location: CLLocation) -> Bool {
        // Filter out locations that are too old (more than 5 seconds)
        let locationAge = -location.timestamp.timeIntervalSinceNow
        if locationAge > 5.0 {
            return false
        }
        
        // Filter out locations with poor accuracy (more than 100 meters)
        if location.horizontalAccuracy > 100 || location.horizontalAccuracy < 0 {
            return false
        }
        
        return true
    }
}

// MARK: - Extensions for convenience

extension LocationManager {
    /// Convert coordinates to address string
    func getAddress(from coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Geocoding error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    completion(nil)
                    return
                }
                
                let addressComponents = [
                    placemark.name,
                    placemark.thoroughfare,
                    placemark.subThoroughfare,
                    placemark.subLocality,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ].compactMap { $0 }
                
                let addressString = addressComponents.joined(separator: ", ")
                completion(addressString.isEmpty ? nil : addressString)
            }
        }
    }
    
    /// Get formatted coordinate string
    func formatCoordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        return "Lat: \(String(format: "%.5f", coordinate.latitude)), Lng: \(String(format: "%.5f", coordinate.longitude))"
    }
}
