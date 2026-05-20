//
//  PrayerTimesViewModel.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

@preconcurrency import Combine
import CoreLocation
import Foundation
@preconcurrency import MapKit
import SwiftUI


@MainActor
final class PrayerUIClock: ObservableObject {
    @Published private(set) var now = Date()
    private var cancellable: AnyCancellable?

    init() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in self?.now = date }
    }

    deinit { cancellable?.cancel() }
}

struct PrayerEntry {
    let name: String
    let date: Date
}

@MainActor
final class PrayerTimesController: NSObject, ObservableObject, CLLocationManagerDelegate {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var cityName: String?
    @Published var nextPrayer: PrayerEntry?
    @Published var followingPrayer: PrayerEntry?
    @Published var windowStartDate: Date?
    @Published var imsakTime: String?
    @Published var sunriseTime: String?
    @Published var hijriDateLabel: String?
    @Published var gregorianDateLabel: String?
    @Published var calculationMethod: PrayerCalculationMethod

    var nextPrayerName: String?  { nextPrayer?.name }
    var nextPrayerDate: Date?    { nextPrayer?.date }
    var nextPrayerTime: String?  { nextPrayer.map { shortTime($0.date) } }
    var followingPrayerName: String? { followingPrayer?.name }
    var followingPrayerTime: String? { followingPrayer.map { shortTime($0.date) } }

    private let locationManager = CLLocationManager()
    private let notificationScheduler = PrayerNotificationScheduler()
    private var hasRequestedThisSession = false
    private var todaySchedule: [PrayerEntry] = []
    private var lastKnownLocation: CLLocation?
    private var scheduleAnchorDate: Date?
    private var tickerCancellable: AnyCancellable?
    private var methodChangeCancellable: AnyCancellable?

    func remainingText(at now: Date) -> String? {
        guard let target = nextPrayer?.date else { return nil }
        let seconds = Int(target.timeIntervalSince(now))
        guard seconds > 0 else { return nil }
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    func progressClamped(at now: Date) -> Double {
        guard
            let start = windowStartDate,
            let end = nextPrayer?.date,
            end > start
        else { return 0 }
        return max(0, min(1, now.timeIntervalSince(start) / end.timeIntervalSince(start)))
    }

    override init() {
        calculationMethod = PrayerCalculationMethod.savedOrDefault()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

        tickerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] now in self?.handleTick(at: now) }

        methodChangeCancellable = NotificationCenter.default
            .publisher(for: .prayerCalculationMethodDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.applyCalculationMethodFromStorage(andRefetch: true)
            }
    }

    func setCalculationMethod(_ method: PrayerCalculationMethod) {
        guard calculationMethod != method else { return }
        calculationMethod = method
        method.persist()
    }

    private func applyCalculationMethodFromStorage(andRefetch: Bool) {
        let saved = PrayerCalculationMethod.savedOrDefault()
        guard calculationMethod != saved else {
            if andRefetch { refetchPrayerTimesIfPossible() }
            return
        }
        calculationMethod = saved
        if andRefetch { refetchPrayerTimesIfPossible() }
    }

    private func refetchPrayerTimesIfPossible() {
        guard let location = lastKnownLocation else { return }
        guard !isLoading else { return }
        isLoading = true
        Task { await fetchPrayerTimes(for: location) }
    }

    func refreshIfNeeded() {
        guard !isLoading else { return }

        if let cachedLocation = lastKnownLocation {
            isLoading = true
            Task { await fetchPrayerTimes(for: cachedLocation) }
            return
        }

        guard nextPrayer == nil || !hasRequestedThisSession else { return }
        hasRequestedThisSession = true
        requestLocation()
    }

    private func requestLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            isLoading = true
            locationManager.requestLocation()
        default:
            errorMessage = "Location permission denied. Enable it in Settings to see prayer times."
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        guard status == .authorizedAlways || status == .authorizedWhenInUse else { return }
        isLoading = true
        manager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isLoading = false
        errorMessage = error.localizedDescription
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            isLoading = false
            return
        }
        lastKnownLocation = location

        if cityName == nil || cityName?.isEmpty == true {
            cityName = Self.coordinateLabel(for: location)
        }

        Task { @MainActor in
            let geocode = await Self.reverseGeocode(location: location)
            if let label = geocode.cityName, label.isEmpty == false {
                cityName = label
            }
            await autoDetectCalculationMethodIfNeeded(countryCode: geocode.countryCode)
        }

        Task { await fetchPrayerTimes(for: location) }
    }

    private func autoDetectCalculationMethodIfNeeded(countryCode: String?) async {
        guard PrayerCalculationMethod.hasSavedPreference == false else { return }
        guard let countryCode else { return }
        let detected = PrayerCalculationMethod.forCountryCode(countryCode)
        guard calculationMethod != detected else { return }
        calculationMethod = detected
        detected.persist(notify: false)
    }

    private func fetchPrayerTimes(for location: CLLocation) async {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let timestamp = Int(Date().timeIntervalSince1970)

        guard let url = AppEndpoints.URLBuilder.alAdhanTimings(
            timestamp: timestamp,
            latitude: lat,
            longitude: lon,
            method: calculationMethod
        ) else {
            isLoading = false
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let envelope = try JSONDecoder().decode(AladhanTimingsEnvelope.self, from: data)
            applyTimings(envelope.data)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private func applyTimings(_ data: AladhanTimingsData) {
        let timings = data.timings
        let now = Date()
        let calendar = Calendar.current
        let scheduleDay = data.date.gregorian.referenceDate ?? now

        hijriDateLabel = data.date.hijri.displayDayMonthYear
        gregorianDateLabel = data.date.gregorian.displayDayMonthYear

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = .current

        func resolve(_ key: String) -> Date? {
            guard let raw = timings[key] else { return nil }
            let clean = raw.split(separator: " ").first.map(String.init) ?? raw
            guard let timeOnly = formatter.date(from: clean) else { return nil }
            var comps = calendar.dateComponents([.year, .month, .day], from: scheduleDay)
            let hm = calendar.dateComponents([.hour, .minute], from: timeOnly)
            comps.hour = hm.hour
            comps.minute = hm.minute
            return calendar.date(from: comps)
        }

        func resolveNightDivision(_ key: String) -> Date? {
            guard var date = resolve(key) else { return nil }
            let fajr = resolve("Fajr")
            let fajrHour = fajr.map { calendar.component(.hour, from: $0) } ?? 5
            let hour = calendar.component(.hour, from: date)
            if hour < fajrHour {
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
            return date
        }

        imsakTime = resolve("Imsak").map { shortTime($0) }
        sunriseTime = resolve("Sunrise").map { shortTime($0) }

        let prayerKeys = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
        todaySchedule = prayerKeys.compactMap { key in
            resolve(key).map { PrayerEntry(name: key, date: $0) }
        }.sorted { $0.date < $1.date }

        guard !todaySchedule.isEmpty else {
            errorMessage = "Unable to resolve prayer schedule from the timetable response."
            return
        }

        let nightDivisions = NightDivisionEntry.Kind.allCases.compactMap { kind -> NightDivisionEntry? in
            guard let date = resolveNightDivision(kind.aladhanKey) else { return nil }
            return NightDivisionEntry(kind: kind, date: date)
        }

        scheduleAnchorDate = calendar.startOfDay(for: scheduleDay)
        refreshPublishedPrayerState(at: now)

        let prayerSnapshot = todaySchedule
        let nightSnapshot = nightDivisions
        Task {
            await notificationScheduler.schedule(
                prayers: prayerSnapshot,
                nightDivisions: nightSnapshot
            )
        }
    }

    private func handleTick(at now: Date) {
        if let anchor = scheduleAnchorDate, !Calendar.current.isDate(now, inSameDayAs: anchor) {
            guard !isLoading, let location = lastKnownLocation else { return }
            isLoading = true
            Task { await fetchPrayerTimes(for: location) }
            return
        }
        if let end = nextPrayer?.date, now >= end {
            refreshPublishedPrayerState(at: now)
        }
    }

    private func refreshPublishedPrayerState(at now: Date) {
        guard !todaySchedule.isEmpty else { return }

        let sorted = todaySchedule
        let upcomingIndex = sorted.firstIndex { $0.date >= now }

        let upcoming: PrayerEntry
        let previous: PrayerEntry?

        if let idx = upcomingIndex {
            upcoming = sorted[idx]
            previous = idx > 0 ? sorted[idx - 1] : nil
        } else {
            let ishaToday = sorted.first { $0.name == "Isha" }
            if let fajrToday = sorted.first(where: { $0.name == "Fajr" }),
               let tomorrowFajr = Calendar.current.date(byAdding: .day, value: 1, to: fajrToday.date) {
                upcoming = PrayerEntry(name: "Fajr", date: tomorrowFajr)
                previous = ishaToday
            } else {
                upcoming = sorted.last!
                previous = sorted.count > 1 ? sorted[sorted.count - 2] : nil
            }
        }

        let following: PrayerEntry? = {
            guard let idx = upcomingIndex else {
                guard let dhuhrToday = sorted.first(where: { $0.name == "Dhuhr" }) else { return nil }
                return Calendar.current.date(byAdding: .day, value: 1, to: dhuhrToday.date)
                    .map { PrayerEntry(name: "Dhuhr", date: $0) }
            }
            if idx + 1 < sorted.count { return sorted[idx + 1] }
            guard let fajrToday = sorted.first(where: { $0.name == "Fajr" }) else { return nil }
            return Calendar.current.date(byAdding: .day, value: 1, to: fajrToday.date)
                .map { PrayerEntry(name: "Fajr", date: $0) }
        }()

        nextPrayer = upcoming
        followingPrayer = following
        windowStartDate = previous?.date ?? now
    }

    private func shortTime(_ date: Date) -> String {
        DateFormatter().apply {
            $0.locale = Locale(identifier: "en_US_POSIX")
            $0.timeStyle = .short
            $0.dateStyle = .none
            $0.timeZone = .current
        }.string(from: date)
    }

    private struct ReverseGeocodeResult: Sendable {
        let cityName: String?
        let countryCode: String?
    }

    nonisolated private static func reverseGeocode(location: CLLocation) async -> ReverseGeocodeResult {
        guard let request = MKReverseGeocodingRequest(location: location) else {
            return ReverseGeocodeResult(cityName: nil, countryCode: nil)
        }
        do {
            let items = try await request.mapItems
            let reps = items.first?.addressRepresentations
            return ReverseGeocodeResult(
                cityName: reps?.cityName,
                countryCode: reps?.__regionCode
            )
        } catch {
            return ReverseGeocodeResult(cityName: nil, countryCode: nil)
        }
    }

    nonisolated private static func coordinateLabel(for location: CLLocation) -> String {
        String(format: "%.3f, %.3f",
               location.coordinate.latitude,
               location.coordinate.longitude)
    }
}

private struct AladhanTimingsEnvelope: Decodable {
    let data: AladhanTimingsData
}

private struct AladhanTimingsData: Decodable {
    let timings: [String: String]
    let date: AladhanTimingsDate
}

private struct AladhanTimingsDate: Decodable {
    let hijri: AladhanCalendarDate
    let gregorian: AladhanCalendarDate
}

private struct AladhanCalendarDate: Decodable {
    let date: String?
    let day: String
    let month: AladhanMonth
    let year: String

    var displayDayMonthYear: String {
        "\(day) \(month.en) \(year)"
    }

    var referenceDate: Date? {
        if let date {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "dd-MM-yyyy"
            formatter.timeZone = .current
            if let parsed = formatter.date(from: date) {
                return parsed
            }
        }
        guard let dayInt = Int(day), let yearInt = Int(year) else { return nil }
        return Calendar.current.date(
            from: DateComponents(year: yearInt, month: month.number, day: dayInt)
        )
    }
}

private struct AladhanMonth: Decodable {
    let number: Int?
    let en: String
}

private extension DateFormatter {
    @discardableResult
    func apply(_ configure: (DateFormatter) -> Void) -> DateFormatter {
        configure(self)
        return self
    }
}
