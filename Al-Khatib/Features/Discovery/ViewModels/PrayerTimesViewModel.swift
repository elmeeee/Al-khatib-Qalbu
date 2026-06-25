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
    @Published var dailyPrayers: [PrayerEntry] = []
    @Published var sunriseDate: Date?

    var nextPrayerName: String?  { nextPrayer?.name }
    var nextPrayerDate: Date?    { nextPrayer?.date }
    var nextPrayerTime: String?  { nextPrayer.map { shortTime($0.date) } }
    var followingPrayerName: String? { followingPrayer?.name }
    var followingPrayerTime: String? { followingPrayer.map { shortTime($0.date) } }

    private let locationManager = CLLocationManager()
    private let notificationScheduler = PrayerNotificationScheduler()
    private var hasRequestedThisSession = false
    private var todaySchedule: [PrayerEntry] = []
    internal var lastKnownLocation: CLLocation?
    private var scheduleAnchorDate: Date?
    private var tickerCancellable: AnyCancellable?
    private var methodChangeCancellable: AnyCancellable?
    private var lastSuccessfulTimingsKey: String?
    private var lastSuccessfulTimingsAt: Date?

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

    private var cachedNightDivisions: [NightDivisionEntry] = []
    private var cachedImsakEntry: PrayerEntry? = nil

    private var notificationOptions: PrayerNotificationPreferences.ScheduleOptions {
        PrayerNotificationPreferences.scheduleOptions()
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

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationPreferencesChange),
            name: PrayerNotificationPreferences.didChangeNotification,
            object: nil
        )
    }

    @objc private func handleNotificationPreferencesChange() {
        rescheduleNotificationsFromCache()
    }

    private func rescheduleNotificationsFromCache() {
        guard !todaySchedule.isEmpty else { return }
        let prayers = todaySchedule
        let imsak = cachedImsakEntry
        let night = cachedNightDivisions
        let options = notificationOptions
        Task {
            await notificationScheduler.schedule(
                prayers: prayers,
                imsakEntry: imsak,
                nightDivisions: night,
                options: options
            )
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
        Task { await fetchPrayerTimes(for: location, bypassDedupe: true) }
    }

    func refreshIfNeeded() {
        guard !isLoading else { return }

        if let cachedLocation = lastKnownLocation {
            isLoading = true
            Task { await fetchPrayerTimes(for: cachedLocation, bypassDedupe: false) }
            return
        }

        guard nextPrayer == nil || !hasRequestedThisSession else { return }
        hasRequestedThisSession = true
        requestLocation()
    }

    func forceRefresh() async {
        if let location = lastKnownLocation {
            guard !isLoading else { return }
            isLoading = true
            await fetchPrayerTimes(for: location, bypassDedupe: true)
            return
        }
        refreshIfNeeded()
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

        Task { await fetchPrayerTimes(for: location, bypassDedupe: false) }
    }

    private func autoDetectCalculationMethodIfNeeded(countryCode: String?) async {
        guard PrayerCalculationMethod.hasSavedPreference == false else { return }
        guard let countryCode else { return }
        let detected = PrayerCalculationMethod.forCountryCode(countryCode)
        guard calculationMethod != detected else { return }
        calculationMethod = detected
        detected.persist(notify: false)
    }

    private func timingsDedupeKey(for location: CLLocation) -> String {
        let lat = (location.coordinate.latitude * 10_000).rounded() / 10_000
        let lon = (location.coordinate.longitude * 10_000).rounded() / 10_000
        let day = Calendar.current.startOfDay(for: Date()).timeIntervalSince1970
        return "\(lat)|\(lon)|\(day)|\(calculationMethod.rawValue)"
    }

    private func fetchPrayerTimes(for location: CLLocation, bypassDedupe: Bool) async {
        let key = timingsDedupeKey(for: location)
        if bypassDedupe == false,
           let prevKey = lastSuccessfulTimingsKey,
           prevKey == key,
           let at = lastSuccessfulTimingsAt,
           Date().timeIntervalSince(at) < 90 {
            isLoading = false
            return
        }

        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude

        let now = Date()
        let calendar = Calendar.current
        let tzOffset = Double(TimeZone.current.secondsFromGMT(for: now)) / 3600.0

        let localTimings = LocalPrayerTimesCalculator.calculate(
            date: now,
            latitude: lat,
            longitude: lon,
            timezoneOffset: tzOffset,
            method: calculationMethod
        )

        // Set date labels locally
        let hijriCalendar = Calendar(identifier: .islamicUmmAlQura)
        let hijriDay = hijriCalendar.component(.day, from: now)
        let hijriYear = hijriCalendar.component(.year, from: now)
        let monthNum = hijriCalendar.component(.month, from: now)
        let hijriMonths = [
            1: "Muharram", 2: "Safar", 3: "Rabi' al-Awwal", 4: "Rabi' al-Thani",
            5: "Jumada al-Awwal", 6: "Jumada al-Thani", 7: "Rajab", 8: "Sha'ban",
            9: "Ramadan", 10: "Shawwal", 11: "Dhu al-Qadah", 12: "Dhu al-Hijjah"
        ]
        let hijriMonthName = hijriMonths[monthNum] ?? "Ramadan"
        hijriDateLabel = "\(hijriDay) \(hijriMonthName) \(hijriYear)"

        let gregFormatter = DateFormatter()
        gregFormatter.locale = Locale(identifier: "en_US")
        gregFormatter.dateFormat = "d MMM yyyy"
        gregorianDateLabel = gregFormatter.string(from: now)

        // Resolve timings
        imsakTime = localTimings["Imsak"].map { shortTime($0) }
        sunriseTime = localTimings["Sunrise"].map { shortTime($0) }
        sunriseDate = localTimings["Sunrise"]

        let prayerKeys = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
        todaySchedule = prayerKeys.compactMap { key in
            localTimings[key].map { PrayerEntry(name: key, date: $0) }
        }.sorted { $0.date < $1.date }

        let timelineKeys = ["Fajr", "Sunrise", "Dhuhr", "Asr", "Maghrib", "Isha"]
        dailyPrayers = timelineKeys.compactMap { key in
            localTimings[key].map { PrayerEntry(name: key, date: $0) }
        }.sorted { $0.date < $1.date }

        errorMessage = nil
        lastSuccessfulTimingsKey = key
        lastSuccessfulTimingsAt = now

        let nightDivisions = NightDivisionEntry.Kind.allCases.compactMap { kind -> NightDivisionEntry? in
            guard let date = localTimings[kind.aladhanKey] else { return nil }
            return NightDivisionEntry(kind: kind, date: date)
        }

        scheduleAnchorDate = calendar.startOfDay(for: now)
        refreshPublishedPrayerState(at: now)

        cachedNightDivisions = nightDivisions
        cachedImsakEntry = localTimings["Imsak"].map { PrayerEntry(name: "Imsak", date: $0) }

        let prayerSnapshot = todaySchedule
        let imsakSnapshot = cachedImsakEntry
        let nightSnapshot = cachedNightDivisions
        let options = notificationOptions

        Task {
            await notificationScheduler.schedule(
                prayers: prayerSnapshot,
                imsakEntry: imsakSnapshot,
                nightDivisions: nightSnapshot,
                options: options
            )
        }

        isLoading = false
    }

    private func handleTick(at now: Date) {
        if let anchor = scheduleAnchorDate, !Calendar.current.isDate(now, inSameDayAs: anchor) {
            guard !isLoading, let location = lastKnownLocation else { return }
            isLoading = true
            Task { await fetchPrayerTimes(for: location, bypassDedupe: false) }
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
