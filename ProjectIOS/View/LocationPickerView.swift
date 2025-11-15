import SwiftUI
import MapKit
import CoreLocationUI

struct LocationPickerView: View {
    @Binding var selectedAddress: String
    @Environment(\.presentationMode) var presentationMode

    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 13.7563, longitude: 100.5018), // Bangkok
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var isPinDragging = false
    @State private var mapTrackingMode: MapUserTrackingMode = .none
    @State private var showAlert = false
    @State private var alertMessage = ""

    @StateObject private var locationManager = LocationManager()

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                interactionModes: .all,
                showsUserLocation: true,
                userTrackingMode: $mapTrackingMode,
                annotationItems: selectedCoordinate.map { [LocationAnnotation(coordinate: $0)] } ?? []) { location in
                MapMarker(coordinate: location.coordinate, tint: .red)
            }
            .ignoresSafeArea(edges: .all)
            .onAppear {
                checkLocationAuthorization()
            }
            .onChange(of: locationManager.location) { newLocation in
                if let location = newLocation {
                    withAnimation {
                        region.center = location.coordinate
                        selectedCoordinate = location.coordinate
                    }
                }
            }
            .onChange(of: locationManager.locationError) { error in
                if let errorMessage = error {
                    alertMessage = errorMessage
                    showAlert = true
                }
            }

            if isPinDragging {
                Image(systemName: "mappin")
                    .font(.title)
                    .foregroundColor(.red)
                    .offset(y: -12)
            }

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 10) {
                    if let coordinate = selectedCoordinate {
                        Text("Selected Location")
                            .font(.headline)
                        Text("Latitude: \(coordinate.latitude, specifier: "%.5f")")
                        Text("Longitude: \(coordinate.longitude, specifier: "%.5f")")
                    } else {
                        Text("Please select a location")
                            .font(.headline)
                    }

                    HStack(spacing: 12) {
                        Button(action: useCurrentLocation) {
                            HStack {
                                Image(systemName: "location.fill")
                                Text("Current Location")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }

                        Button(action: togglePinMode) {
                            HStack {
                                Image(systemName: isPinDragging ? "checkmark" : "mappin")
                                Text(isPinDragging ? "Confirm Location" : "Drop Pin")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(isPinDragging ? Color.green : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                    }

                    if selectedCoordinate != nil {
                        Button("Use This Location") {
                            if let coordinate = selectedCoordinate {
                                convertCoordinateToAddress(coordinate: coordinate)
                                selectedAddress = "Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)"
                                presentationMode.wrappedValue.dismiss() // ปิดหน้า LocationPickerView
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color(.systemBackground))
                        .shadow(radius: 5)
                )
                .padding()
            }
        }
        .navigationTitle("Select Location")
        .navigationBarTitleDisplayMode(.inline)
        .gesture(
            DragGesture()
                .onChanged { _ in
                    if isPinDragging {
                        selectedCoordinate = region.center
                    }
                }
        )
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Location Error"),
                  message: Text(alertMessage),
                  dismissButton: .default(Text("OK")))
        }
    }

    // MARK: - Location and Pin Handling

    private func checkLocationAuthorization() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestLocation()
        case .restricted, .denied:
            alertMessage = "The app is not authorized to access location. Please enable location access in settings."
            showAlert = true
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        @unknown default:
            break
        }
    }

    private func useCurrentLocation() {
        locationManager.requestLocation()
    }

    private func togglePinMode() {
        withAnimation {
            isPinDragging.toggle()
            if isPinDragging {
                selectedCoordinate = region.center
            }
        }
    }

    private func convertCoordinateToAddress(coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let geocoder = CLGeocoder()

        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                alertMessage = "Failed to convert coordinates to address: \(error.localizedDescription)"
                showAlert = true
                return
            }

            if let placemark = placemarks?.first {
                let addressString = [
                    placemark.name,
                    placemark.thoroughfare,
                    placemark.subThoroughfare,
                    placemark.subLocality,
                    placemark.locality,
                    placemark.administrativeArea,
                    placemark.postalCode,
                    placemark.country
                ].compactMap { $0 }.joined(separator: ", ")

                selectedAddress = addressString
            } else {
                alertMessage = "Failed to convert coordinates to address."
                showAlert = true
            }
        }
    }
}

// เพิ่มฟังก์ชัน hideKeyboard
#if canImport(UIKit)
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

struct LocationAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
