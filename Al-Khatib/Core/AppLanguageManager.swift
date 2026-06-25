//
//  AppLanguageManager.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case indonesian = "id"
    case malay = "ms"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .indonesian: return "Bahasa Indonesia"
        case .malay: return "Bahasa Melayu"
        }
    }
}

@MainActor
class AppLanguageManager: ObservableObject {
    static let shared = AppLanguageManager()
    static let storageKey = "selected_app_language"
    
    @Published var currentLanguage: AppLanguage = .english {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
            NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
        }
    }
    
    private init() {
        if let raw = UserDefaults.standard.string(forKey: Self.storageKey),
           let lang = AppLanguage(rawValue: raw) {
            currentLanguage = lang
        } else {
            let localeLang = Locale.preferredLanguages.first ?? "en"
            if localeLang.hasPrefix("id") {
                currentLanguage = .indonesian
            } else if localeLang.hasPrefix("ms") {
                currentLanguage = .malay
            } else {
                currentLanguage = .english
            }
        }
    }
    
    func localize(_ key: String) -> String {
        let dict = translations[key]
        return dict?[currentLanguage] ?? dict?[.english] ?? key
    }
    
    private let translations: [String: [AppLanguage: String]] = [
        // Tabs
        "tab_today": [.english: "Today", .indonesian: "Hari Ini", .malay: "Hari Ini"],
        "tab_quran": [.english: "Quran", .indonesian: "Al-Quran", .malay: "Al-Quran"],
        "tab_reflections": [.english: "Reflections", .indonesian: "Refleksi", .malay: "Refleksi"],
        "tab_tools": [.english: "Tools", .indonesian: "Fitur", .malay: "Fitur"],
        "tab_profile": [.english: "Profile", .indonesian: "Profil", .malay: "Profil"],
        
        // Profile Settings
        // Profile Settings
        "general": [.english: "General", .indonesian: "Umum", .malay: "Umum"],
        "font_size": [.english: "Font Size", .indonesian: "Ukuran Font", .malay: "Saiz Fon"],
        "app_language": [.english: "App Language", .indonesian: "Bahasa Aplikasi", .malay: "Bahasa Aplikasi"],
        "translation_language": [.english: "Translation Language", .indonesian: "Bahasa Terjemahan", .malay: "Bahasa Terjemahan"],
        "translator": [.english: "Translator", .indonesian: "Penerjemah", .malay: "Penterjemah"],
        "show_translation": [.english: "Show Translation", .indonesian: "Tampilkan Terjemahan", .malay: "Tunjukkan Terjemahan"],
        
        "prayer_setting": [.english: "Prayer Setting", .indonesian: "Pengaturan Shalat", .malay: "Tetapan Solat"],
        "prayer_calc": [.english: "Prayer calculation", .indonesian: "Perhitungan Shalat", .malay: "Kiraan Solat"],
        "adhan_voice": [.english: "Adhan Voice", .indonesian: "Suara Adzan", .malay: "Suara Azan"],
        
        "notifications": [.english: "Notifications", .indonesian: "Notifikasi", .malay: "Notifikasi"],
        "notif_adhan": [.english: "Adhan Notifications", .indonesian: "Notifikasi Adzan", .malay: "Notifikasi Azan"],
        "notif_imsak": [.english: "Imsak Notification", .indonesian: "Notifikasi Imsak", .malay: "Notifikasi Imsak"],
        "notif_midnight": [.english: "Midnight Notification", .indonesian: "Notifikasi Tengah Malam", .malay: "Notifikasi Tengah Malam"],
        "notif_first_third": [.english: "First Third Notification", .indonesian: "Notifikasi Sepertiga Malam", .malay: "Notifikasi Sepertiga Malam"],
        "notif_tahajud": [.english: "Tahajud Notification", .indonesian: "Notifikasi Tahajud", .malay: "Notifikasi Tahajjud"],
        "notif_daily_verse": [.english: "Daily Verse Notification", .indonesian: "Notifikasi Ayat Harian", .malay: "Notifikasi Ayat Harian"],
        
        "sign_in": [.english: "Sign In", .indonesian: "Masuk Akun", .malay: "Log Masuk"],
        "sign_out": [.english: "Sign Out", .indonesian: "Keluar Akun", .malay: "Log Keluar"],
        
        // Settings details
        "system_default": [.english: "System Default", .indonesian: "Default Sistem", .malay: "Lalai Sistem"],
        "verse_of_the_day": [.english: "Verse of the day", .indonesian: "Ayat hari ini", .malay: "Ayat hari ini"],
        "daily_verse_sub": [.english: "Today’s surah & translation in your notification", .indonesian: "Surah & terjemahan hari ini di notifikasi Anda", .malay: "Surah & terjemahan hari ini di notifikasi Anda"],
        "morning_time": [.english: "Morning time", .indonesian: "Waktu pagi", .malay: "Waktu pagi"],
        "prayer_times": [.english: "Prayer times", .indonesian: "Waktu shalat", .malay: "Waktu solat"],
        "prayer_times_sub": [.english: "Fajr, Dhuhr, Asr, Maghrib & Isha", .indonesian: "Subuh, Dzuhur, Ashar, Maghrib & Isya", .malay: "Subuh, Zohor, Asar, Maghrib & Isyak"],
        "imsak_sub": [.english: "Reminder before Fajr while fasting", .indonesian: "Peringatan sebelum Subuh saat berpuasa", .malay: "Peringatan sebelum Subuh ketika berpuasa"],
        "midnight_sub": [.english: "Halfway through the night", .indonesian: "Tengah malam", .malay: "Tengah malam"],
        "first_third_sub": [.english: "Early night rest reminder", .indonesian: "Peringatan awal malam", .malay: "Peringatan awal malam"],
        "tahajud_sub": [.english: "Best time for night prayer", .indonesian: "Waktu terbaik untuk shalat malam", .malay: "Waktu terbaik untuk solat malam"],
        "font_small": [.english: "Small", .indonesian: "Kecil", .malay: "Kecil"],
        "font_medium": [.english: "Medium", .indonesian: "Sedang", .malay: "Sederhana"],
        "font_large": [.english: "Large", .indonesian: "Besar", .malay: "Besar"],
        "font_extra_large": [.english: "Extra large", .indonesian: "Sangat besar", .malay: "Sangat besar"],
        
        "notif_disabled_title": [.english: "Notifications disabled", .indonesian: "Notifikasi dinonaktifkan", .malay: "Notifikasi dinyahaktifkan"],
        "notif_disabled_msg": [.english: "Allow notifications for Al-Khatib in Settings to receive reminders.", .indonesian: "Izinkan notifikasi untuk Al-Khatib di Pengaturan untuk menerima pengingat.", .malay: "Benarkan notifikasi untuk Al-Khatib di Tetapan untuk menerima peringatan."],
        "open_settings": [.english: "Open Settings", .indonesian: "Buka Pengaturan", .malay: "Buka Tetapan"],
        "close": [.english: "Close", .indonesian: "Tutup", .malay: "Tutup"],
        "cancel": [.english: "Cancel", .indonesian: "Batal", .malay: "Batal"],
        
        // Tools list
        "tool_qibla": [.english: "Qibla Finder", .indonesian: "Arah Kiblat", .malay: "Arah Kiblat"],
        "tool_qibla_sub": [.english: "Locate Kaaba direction", .indonesian: "Cari arah kiblat", .malay: "Cari arah kiblat"],
        "tool_zakat": [.english: "Zakat Calculator", .indonesian: "Kalkulator Zakat", .malay: "Kalkulator Zakat"],
        "tool_zakat_sub": [.english: "Calculate your zakat", .indonesian: "Hitung zakat Anda", .malay: "Kira zakat anda"],
        "tool_faraidh": [.english: "Inheritance Calculator", .indonesian: "Kalkulator Waris (Faraidh)", .malay: "Kalkulator Waris (Faraidh)"],
        "tool_faraidh_sub": [.english: "Islamic inheritance", .indonesian: "Pembagian warisan Islam", .malay: "Pembahagian waris Islam"],
        "tool_manzil": [.english: "Manzil Protection", .indonesian: "Manzil (Ayat Pelindung)", .malay: "Manzil (Ayat Pelindung)"],
        "tool_manzil_sub": [.english: "Quranic protection verses", .indonesian: "Ayat-ayat perlindungan Al-Quran", .malay: "Ayat-ayat perlindungan Al-Quran"],
        "tool_qiyam": [.english: "Qiyam Tracker", .indonesian: "Jurnal Tahajud", .malay: "Diari Tahajjud"],
        "tool_qiyam_sub": [.english: "Tahajjud logging & guide", .indonesian: "Pencatatan & panduan Tahajud", .malay: "Catatan & panduan Tahajjud"],
        "tool_tasbih": [.english: "Digital Tasbih", .indonesian: "Tasbih Digital", .malay: "Tasbih Digital"],
        "tool_tasbih_sub": [.english: "Tasbih counter", .indonesian: "Penghitung tasbih", .malay: "Penghitung tasbih"],
        "tool_hijri": [.english: "Hijri Calendar", .indonesian: "Kalender Hijriah", .malay: "Kalendar Hijriah"],
        "tool_doa_zikir": [.english: "Doa & Zikir", .indonesian: "Doa & Dzikir", .malay: "Doa & Zikir"],
        "tool_doa_zikir_sub": [.english: "Collection of prayers", .indonesian: "Kumpulan doa & dzikir", .malay: "Kumpulan doa & zikir"],
        "tools_title": [.english: "Spiritual Tools", .indonesian: "Fitur Ibadah", .malay: "Fitur Ibadah"],
        "tools_desc": [.english: "Enhance your daily worship with these local tools and calculators.", .indonesian: "Tingkatkan ibadah harian Anda dengan fitur-fitur dan kalkulator berikut.", .malay: "Tingkatkan ibadah harian anda dengan fitur-fitur dan kalkulator berikut."],
        
        // Quran & Juz Reader
        "surah": [.english: "Surah", .indonesian: "Surah", .malay: "Surah"],
        "juz": [.english: "Juz", .indonesian: "Juz", .malay: "Juz"],
        "verses": [.english: "Verses", .indonesian: "Ayat", .malay: "Ayat"],
        "no_chapters": [.english: "No chapters found", .indonesian: "Tidak ada surah ditemukan", .malay: "Tiada surah dijumpai"],
        "try_again": [.english: "Try Again", .indonesian: "Coba Lagi", .malay: "Cuba Lagi"],
        "continue_reading": [.english: "Continue reading", .indonesian: "Lanjutkan membaca", .malay: "Teruskan membaca"],
        "starts_at": [.english: "Starts at", .indonesian: "Mulai dari", .malay: "Mula dari"],
        "quran_title": [.english: "Quran", .indonesian: "Al-Quran", .malay: "Al-Quran"],
        
        // Faraidh
        "faraidh_title": [.english: "Inheritance Calculator", .indonesian: "Kalkulator Waris", .malay: "Kalkulator Waris"],
        "faraidh_profile": [.english: "Deceased Profile", .indonesian: "Profil Pewaris", .malay: "Profil Pewaris"],
        "faraidh_name": [.english: "Deceased Name", .indonesian: "Nama Pewaris", .malay: "Nama Pewaris"],
        "faraidh_gender": [.english: "Gender", .indonesian: "Jenis Kelamin", .malay: "Jantina"],
        "faraidh_male": [.english: "Male", .indonesian: "Laki-laki", .malay: "Lelaki"],
        "faraidh_female": [.english: "Female", .indonesian: "Perempuan", .malay: "Perempuan"],
        "faraidh_madhhab": [.english: "Madhhab", .indonesian: "Mazhab", .malay: "Mazhab"],
        "faraidh_out_wedlock": [.english: "Deceased Born Out of Wedlock", .indonesian: "Pewaris Lahir di Luar Nikah", .malay: "Pewaris Lahir Luar Nikah"],
        "faraidh_estate": [.english: "Estate & Deductions", .indonesian: "Harta & Pengurangan", .malay: "Harta & Potongan"],
        "faraidh_heirs": [.english: "Select Surviving Heirs", .indonesian: "Pilih Ahli Waris", .malay: "Pilih Ahli Waris"],
        "faraidh_btn_calc": [.english: "Calculate Inheritance Shares", .indonesian: "Hitung Pembagian Waris", .malay: "Kira Bahagian Waris"]
    ]
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
}
