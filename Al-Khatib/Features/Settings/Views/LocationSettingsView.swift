import SwiftUI
import CoreLocation

struct LocationSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    @AppStorage("use_manual_location") private var useManualLocation = false
    @AppStorage("manual_latitude") private var manualLatitude = 3.1390
    @AppStorage("manual_longitude") private var manualLongitude = 101.6869
    @AppStorage("manual_city_name") private var manualCityName = "Kuala Lumpur"
    
    @State private var latString = ""
    @State private var lonString = ""
    @State private var cityNameInput = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Inject Controller to refresh prayer times instantly
    @EnvironmentObject private var prayerController: PrayerTimesController
    
    struct CityPreset {
        let nameKey: String
        let lat: Double
        let lon: Double
        let defaultName: String
    }
    
    private let presets = [
        CityPreset(nameKey: "mecca", lat: 21.4225, lon: 39.8262, defaultName: "Mecca"),
        CityPreset(nameKey: "jakarta", lat: -6.2088, lon: 106.8456, defaultName: "Jakarta"),
        CityPreset(nameKey: "kuala_lumpur", lat: 3.1390, lon: 101.6869, defaultName: "Kuala Lumpur"),
        CityPreset(nameKey: "singapore", lat: 1.3521, lon: 103.8198, defaultName: "Singapore")
    ]
    
    var body: some View {
        Form {
            Section(header: Text(languageManager.localize("location_source"))) {
                Toggle(isOn: $useManualLocation) {
                    Text(languageManager.localize("set_manually"))
                }
                .onChange(of: useManualLocation) { _ in
                    triggerRefresh()
                }
            }
            
            if useManualLocation {
                Section(header: Text(languageManager.localize("preset_cities"))) {
                    ForEach(presets, id: \.nameKey) { preset in
                        Button(action: {
                            applyPreset(preset)
                        }) {
                            HStack {
                                Text(languageManager.localize(preset.nameKey))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(String(format: "%.4f, %.4f", preset.lat, preset.lon))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section(header: Text(languageManager.localize("set_manually"))) {
                    HStack {
                        Text(languageManager.localize("city_name"))
                            .frame(width: 100, alignment: .leading)
                        TextField("Kuala Lumpur", text: $cityNameInput)
                            .autocorrectionDisabled()
                    }
                    
                    HStack {
                        Text(languageManager.localize("latitude"))
                            .frame(width: 100, alignment: .leading)
                        TextField("e.g. 3.1390", text: $latString)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text(languageManager.localize("longitude"))
                            .frame(width: 100, alignment: .leading)
                        TextField("e.g. 101.6869", text: $lonString)
                            .keyboardType(.decimalPad)
                    }
                    
                    Button(action: saveManualLocation) {
                        Text(languageManager.localize("save_location"))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .bold()
                    }
                }
            } else {
                Section(header: Text(languageManager.localize("gps_status"))) {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        Text(languageManager.localize("gps_active"))
                    }
                }
            }
        }
        .navigationTitle(languageManager.localize("location_settings_title"))
        .onAppear {
            loadCurrentValues()
        }
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Location"), message: Text(alertMessage), dismissButton: .default(Text(languageManager.localize("close"))))
        }
    }
    
    private func loadCurrentValues() {
        cityNameInput = manualCityName
        latString = String(format: "%.4f", manualLatitude)
        lonString = String(format: "%.4f", manualLongitude)
    }
    
    private func applyPreset(_ preset: CityPreset) {
        cityNameInput = languageManager.localize(preset.nameKey)
        latString = String(format: "%.4f", preset.lat)
        lonString = String(format: "%.4f", preset.lon)
        saveManualLocation()
    }
    
    private func saveManualLocation() {
        guard let lat = Double(latString), let lon = Double(lonString) else {
            alertMessage = "Invalid latitude or longitude format."
            showingAlert = true
            return
        }
        
        manualLatitude = lat
        manualLongitude = lon
        manualCityName = cityNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Custom Location" : cityNameInput
        
        triggerRefresh()
        
        alertMessage = "Location updated successfully."
        showingAlert = true
    }
    
    private func triggerRefresh() {
        Task {
            await prayerController.forceRefresh()
        }
    }
}
