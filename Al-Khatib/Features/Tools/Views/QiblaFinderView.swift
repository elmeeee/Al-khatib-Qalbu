import SwiftUI
import CoreLocation
import AVFoundation
import Combine

@MainActor
final class QiblaLocationHeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var heading: Double = 0
    @Published var latitude: Double? = nil
    @Published var longitude: Double? = nil
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    @Published var bearing: Double = 0
    @Published var distanceKm: Double = 0
    @Published var isAligned: Bool = false
    
    private var lastHapticSent = false
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 1
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func start() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            start()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        latitude = loc.coordinate.latitude
        longitude = loc.coordinate.longitude
        recompute()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // True heading is preferred if available (>0), otherwise magnetic
        heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        recompute()
    }
    
    private func recompute() {
        guard let lat = latitude, let lng = longitude else { return }
        bearing = QiblaCalculator.bearingToKaaba(latitude: lat, longitude: lng)
        distanceKm = QiblaCalculator.distanceToKaabaKm(latitude: lat, longitude: lng)
        
        let relativeHeading = (bearing - heading + 360.0).truncatingRemainder(dividingBy: 360.0)
        let aligned = relativeHeading <= 8.0 || relativeHeading >= 352.0
        
        if aligned != isAligned {
            isAligned = aligned
            if aligned && !lastHapticSent {
                triggerHapticFeedback()
                lastHapticSent = true
            } else if !aligned {
                lastHapticSent = false
            }
        }
    }
    
    private func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

struct QiblaFinderView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var manager = QiblaLocationHeadingManager()
    @State private var selectedMode = 0 // 0 for AR, 1 for Compass
    
    var body: some View {
        ZStack {
            // Background View
            if selectedMode == 0 {
                ARCameraPreviewContainer()
                    .ignoresSafeArea()
            } else {
                RadialGradient(
                    colors: [Color(red: 15/255, green: 23/255, blue: 42/255), Color(red: 2/255, green: 6/255, blue: 23/255)],
                    center: .center,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()
            }
            
            // UI Overlay
            VStack {
                // Header Row
                HStack(spacing: 12) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    
                    Text("Qibla Finder")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                // Mode Picker
                Picker("Mode", selection: $selectedMode) {
                    Text("AR Mode").tag(0)
                    Text("Compass Mode").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 24)
                .padding(.top, 8)
                
                Spacer()
                
                if manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted {
                    locationRequiredOverlay
                } else if manager.latitude == nil {
                    ProgressView("Locating...")
                        .tint(.white)
                        .foregroundColor(.white)
                } else {
                    compassCenterDial
                }
                
                Spacer()
                
                // Footer bearing and distance
                bottomIndicatorCard
            }
        }
        .onAppear {
            manager.requestPermissions()
            manager.start()
        }
        .onDisappear {
            manager.stop()
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    private var locationRequiredOverlay: some View {
        VStack(spacing: 14) {
            Image(systemName: "location.slash.fill")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text("Location permission is required to calculate the direction of the Qibla.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal, 40)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.Token.deepEmerald)
        }
    }
    
    private var compassCenterDial: some View {
        VStack(spacing: 30) {
            ZStack {
                // Outer circle
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 3)
                    .frame(width: 280, height: 280)
                
                // Outer markers
                ForEach(0..<12) { i in
                    Rectangle()
                        .fill(Color.white.opacity(i % 3 == 0 ? 0.4 : 0.2))
                        .frame(width: i % 3 == 0 ? 3 : 2, height: i % 3 == 0 ? 15 : 10)
                        .offset(y: -130)
                        .rotationEffect(.degrees(Double(i) * 30.0))
                }
                
                // North indicator
                Text("N")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.red)
                    .offset(y: -148)
                    .rotationEffect(.degrees(manager.bearing - manager.heading))
                
                // Compass Needle Group
                ZStack {
                    // Kaaba Needle (Orange/Gold Line)
                    Image(systemName: "arrow.up")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(manager.isAligned ? Color.Token.gold : Color.orange)
                        .offset(y: -90)
                    
                    // Kaaba symbol marker at the top of the needle
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 14))
                        .foregroundColor(manager.isAligned ? Color.Token.gold : Color.orange)
                        .offset(y: -126)
                    
                    // Pivot center dot
                    Circle()
                        .fill(manager.isAligned ? Color.Token.gold : Color.orange)
                        .frame(width: 14, height: 14)
                }
                .rotationEffect(.degrees(manager.bearing - manager.heading))
                .animation(.easeOut(duration: 0.15), value: manager.bearing - manager.heading)
                
                // Aligned Glow Indicator
                if manager.isAligned {
                    Circle()
                        .stroke(Color.Token.gold.opacity(0.3), lineWidth: 8)
                        .frame(width: 290, height: 290)
                }
            }
            .frame(width: 300, height: 300)
            
            // Bearing label HUD inside dial area
            Text("Kaaba Bearing: \(Int(manager.bearing.rounded()))°")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.white.opacity(0.12)))
        }
    }
    
    private var bottomIndicatorCard: some View {
        VStack(spacing: 8) {
            if manager.isAligned {
                Text("ALIGNED WITH KAABA")
                    .font(.subheadline.bold())
                    .foregroundColor(Color.Token.gold)
                    .tracking(2.0)
            } else {
                Text("ROTATE PHONE")
                    .font(.subheadline.bold())
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)
            }
            
            HStack(spacing: 24) {
                VStack(spacing: 3) {
                    Text("Heading")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Text("\(Int(manager.heading.rounded()))°")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                
                Divider()
                    .frame(height: 35)
                    .background(Color.white.opacity(0.15))
                
                VStack(spacing: 3) {
                    Text("Distance")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    Text(String(format: "%.0f km", manager.distanceKm))
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(manager.isAligned ? Color.Token.gold.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1.5)
            )
        }
        .padding(.bottom, 36)
        .padding(.horizontal, 24)
    }
}

// AR Camera View Components
struct ARCameraPreviewContainer: View {
    @State private var session = AVCaptureSession()
    @State private var permissionGranted = false
    
    var body: some View {
        ZStack {
            if permissionGranted {
                CameraPreviewView(session: session)
                    .onAppear {
                        DispatchQueue.global(qos: .userInitiated).async {
                            session.startRunning()
                        }
                    }
                    .onDisappear {
                        DispatchQueue.global(qos: .userInitiated).async {
                            session.stopRunning()
                        }
                    }
            } else {
                Color.black
                    .onAppear {
                        checkPermission()
                    }
            }
        }
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            permissionGranted = true
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.permissionGranted = true
                        self.setupSession()
                    }
                }
            }
        default:
            permissionGranted = false
        }
    }
    
    private func setupSession() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {}
    
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}
