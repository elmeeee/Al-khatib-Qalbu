//
//  AppLanguageManager.swift
//  Sāat
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
        if let val = dict?[currentLanguage] {
            return val
        }
        if currentLanguage == .malay, let idVal = dict?[.indonesian] {
            return idVal
        }
        return dict?[.english] ?? key
    }
    
    private let translations: [String: [AppLanguage: String]] = [
        // Tabs
        "tab_today": [.english: "Today", .indonesian: "Hari Ini", .malay: "Hari Ini"],
        "tab_quran": [.english: "Quran", .indonesian: "Al-Quran", .malay: "Al-Quran"],
        "tab_reflections": [.english: "Reflections", .indonesian: "Refleksi", .malay: "Refleksi"],
        "tab_tools": [.english: "Tools", .indonesian: "Fitur", .malay: "Fitur"],
        "tab_profile": [.english: "Profile", .indonesian: "Profil", .malay: "Profil"],
        "share": [.english: "Share", .indonesian: "Bagikan", .malay: "Kongsi"],
        
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
        "sync_reflections": [.english: "Sync Reflections", .indonesian: "Sinkronkan Renungan", .malay: "Segerak Renungan"],
        "sign_in_prompt": [.english: "Sign in to back up your progress.", .indonesian: "Masuk untuk menyimpan progres Anda.", .malay: "Log masuk untuk menyimpan kemajuan anda."],

        "imsak": [.english: "Imsak", .indonesian: "Imsak", .malay: "Imsak"],
        "midnight": [.english: "Midnight", .indonesian: "Tengah Malam", .malay: "Tengah Malam"],
        "first_third_night": [.english: "First Third of Night", .indonesian: "Sepertiga Malam Pertama", .malay: "Sepertiga Malam Pertama"],
        "tahajud": [.english: "Tahajud", .indonesian: "Tahajud", .malay: "Tahajjud"],


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
        "notif_disabled_msg": [.english: "Allow notifications for Sāat in Settings to receive reminders.", .indonesian: "Izinkan notifikasi untuk Sāat di Pengaturan untuk menerima pengingat.", .malay: "Benarkan notifikasi untuk Sāat di Tetapan untuk menerima peringatan."],
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
        "starts_at": [.english: "Starts at", .indonesian: "Mulai dari", .malay: "Mula dari"],
        "quran_title": [.english: "Quran", .indonesian: "Al-Quran", .malay: "Al-Quran"],
        "quran_subtitle": [.english: "114 Surahs · The Noble Quran", .indonesian: "114 Surah · Al-Quran Al-Karim", .malay: "114 Surah · Al-Quran Al-Karim"],
        "quran_subtitle_juz": [.english: "30 Juz · The Noble Quran", .indonesian: "30 Juz · Al-Quran Al-Karim", .malay: "30 Juz · Al-Quran Al-Karim"],

        // Search
        "search_quran_placeholder": [.english: "Search surah, number or keyword…", .indonesian: "Cari surah, nomor, atau kata kunci…", .malay: "Cari surah, nombor atau kata kunci…"],
        "search_quran_a11y": [.english: "Search Quran surah", .indonesian: "Cari surah Al-Quran", .malay: "Cari surah Al-Quran"],
        "clear_search_a11y": [.english: "Clear search", .indonesian: "Hapus pencarian", .malay: "Kosongkan carian"],
        "search_no_results": [.english: "No surah found for", .indonesian: "Tidak ada surah yang ditemukan untuk", .malay: "Tiada surah ditemui untuk"],


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
        "faraidh_btn_calc": [.english: "Calculate Inheritance Shares", .indonesian: "Hitung Pembagian Waris", .malay: "Kira Bahagian Waris"],
        
        // Onboarding
        "onboarding_welcome_title": [.english: "Welcome to Sāat", .indonesian: "Selamat Datang di Sāat", .malay: "Selamat Datang di Sāat"],
        "onboarding_welcome_subtitle": [.english: "Your premium, offline companion to reflect on the Holy Quran and track spiritual habits.", .indonesian: "Pendamping ibadah luring premium Anda untuk merenungkan Al-Quran & mencatat kebiasaan spiritual harian.", .malay: "Pendamping ibadah luar talian premium anda untuk merenungkan Al-Quran & mencatat tabiat spiritual harian."],
        "onboarding_select_language": [.english: "Select Language", .indonesian: "Pilih Bahasa", .malay: "Pilih Bahasa"],
        "onboarding_location_title": [.english: "Accurate Prayer Times", .indonesian: "Waktu Shalat Akurat", .malay: "Waktu Solat Tepat"],
        "onboarding_location_subtitle": [.english: "We compute prayer times completely offline. Grant location access or set it later to get started.", .indonesian: "Kami menghitung waktu shalat sepenuhnya secara luring. Izinkan lokasi atau atur nanti untuk memulai.", .malay: "Kami mengira waktu solat sepenuhnya secara luar talian. Benarkan lokasi atau tetapkan kemudian untuk bermula."],
        "onboarding_use_gps": [.english: "Enable GPS Location", .indonesian: "Aktifkan Lokasi GPS", .malay: "Aktifkan Lokasi GPS"],
        "onboarding_location_skip": [.english: "Set Location Later", .indonesian: "Atur Lokasi Nanti", .malay: "Tetapkan Lokasi Kemudian"],
        "onboarding_notifications_title": [.english: "Stay Notified", .indonesian: "Tetap Terhubung", .malay: "Kekal Berhubung"],
        "onboarding_notifications_subtitle": [.english: "Receive daily verse of the day reminders and beautiful Adhan sound alerts at prayer times.", .indonesian: "Dapatkan pengingat ayat pilihan harian serta alarm kumandang Adzan merdu setiap masuk waktu shalat.", .malay: "Terima peringatan ayat harian pilihan serta amaran laungan Azan merdu setiap masuk waktu solat."],
        "onboarding_enable_notifications": [.english: "Enable Notifications", .indonesian: "Aktifkan Notifikasi", .malay: "Aktifkan Notifikasi"],
        "onboarding_notifications_skip": [.english: "Skip Notifications", .indonesian: "Lewati Notifikasi", .malay: "Langkau Notifikasi"],
        "onboarding_widgets_title": [.english: "Worship at a Glance", .indonesian: "Ibadah Sekilas Pandang", .malay: "Ibadah Sekilas Pandang"],
        "onboarding_widgets_subtitle": [.english: "Pin custom widgets to your home screen to see today's verse and countdowns to the next prayer times.", .indonesian: "Sematkan widget khusus di layar beranda untuk memantau ayat pilihan hari ini dan hitung mundur waktu shalat.", .malay: "Sematkan widget khas di skrin utama untuk memantau ayat pilihan hari ini dan hitung mundur waktu solat."],
        "onboarding_get_started": [.english: "Get Started", .indonesian: "Mulai Sekarang", .malay: "Mula Sekarang"],
        "onboarding_continue": [.english: "Continue", .indonesian: "Lanjutkan", .malay: "Teruskan"],
        "onboarding_step": [.english: "Step %d of 4", .indonesian: "Langkah %d dari 4", .malay: "Langkah %d dari 4"],
        
        // Qibla Finder
        "qibla_ar_mode": [.english: "AR Mode", .indonesian: "Mode AR", .malay: "Mod AR"],
        "qibla_compass_mode": [.english: "Compass Mode", .indonesian: "Mode Kompas", .malay: "Mod Kompas"],
        "qibla_locating": [.english: "Locating...", .indonesian: "Mencari lokasi...", .malay: "Mencari lokasi..."],
        "qibla_location_required": [.english: "Location permission is required to calculate the direction of the Qibla.", .indonesian: "Izin lokasi diperlukan untuk menghitung arah Kiblat.", .malay: "Kebenaran lokasi diperlukan untuk mengira arah Kiblat."],
        "qibla_bearing_format": [.english: "Kaaba Bearing: %d°", .indonesian: "Arah Ka'bah: %d°", .malay: "Arah Kaabah: %d°"],
        "qibla_aligned": [.english: "ALIGNED WITH KAABA", .indonesian: "SEJAJAR DENGAN KA'BAH", .malay: "SEJAJAR DENGAN KAABAH"],
        "qibla_rotate_phone": [.english: "ROTATE PHONE", .indonesian: "PUTAR PONSEL", .malay: "PUTAR TELEFON"],
        "qibla_heading": [.english: "Heading", .indonesian: "Arah Hadap", .malay: "Arah Hadap"],
        "qibla_distance": [.english: "Distance", .indonesian: "Jarak", .malay: "Jarak"],

        // Zakat Calculator
        "zakat_maal": [.english: "Zakat Maal", .indonesian: "Zakat Maal", .malay: "Zakat Maal"],
        "zakat_fitrah": [.english: "Zakat Fitrah", .indonesian: "Zakat Fitrah", .malay: "Zakat Fitrah"],
        "zakat_live_gold": [.english: "Live Gold Price", .indonesian: "Harga Emas Live", .malay: "Harga Emas Live"],
        "zakat_source_format": [.english: "Source: %@", .indonesian: "Sumber: %@", .malay: "Sumber: %@"],
        "zakat_gold_default_format": [.english: "IDR %@ / gram (Default)", .indonesian: "IDR %@ / gram (Default)", .malay: "IDR %@ / gram (Lalai)"],
        "zakat_assets_liabilities": [.english: "Assets & Liabilities", .indonesian: "Harta & Kewajiban", .malay: "Harta & Liabiliti"],
        "zakat_cash_savings": [.english: "Cash & Savings", .indonesian: "Uang Tunai & Tabungan", .malay: "Wang Tunai & Simpanan"],
        "zakat_gold_owned": [.english: "Gold Owned (grams)", .indonesian: "Emas Dimiliki (gram)", .malay: "Emas Dimiliki (gram)"],
        "zakat_silver_owned": [.english: "Silver Owned (grams)", .indonesian: "Perak Dimiliki (gram)", .malay: "Perak Dimiliki (gram)"],
        "zakat_investments": [.english: "Investments / Stocks", .indonesian: "Investasi / Saham", .malay: "Pelaburan / Saham"],
        "zakat_debts": [.english: "Outstanding Debts", .indonesian: "Utang Jatuh Tempo", .malay: "Hutang Terhutang"],
        "zakat_custom_gold": [.english: "Custom Gold Price", .indonesian: "Harga Emas Kustom", .malay: "Harga Emas Kustom"],
        "zakat_maal_results": [.english: "Maal Results", .indonesian: "Hasil Zakat Maal", .malay: "Keputusan Zakat Maal"],
        "zakat_net_wealth": [.english: "Zakatable Net Wealth", .indonesian: "Kekayaan Wajib Zakat", .malay: "Kekayaan Wajib Zakat"],
        "zakat_nisab_limit": [.english: "Nisab Limit (85g Gold)", .indonesian: "Batas Nisab (85g Emas)", .malay: "Had Nisab (85g Emas)"],
        "zakat_status": [.english: "Status", .indonesian: "Status", .malay: "Status"],
        "zakat_meets_nisab": [.english: "Meets Nisab", .indonesian: "Mencapai Nisab", .malay: "Melepasi Nisab"],
        "zakat_no_nisab": [.english: "Does not meet Nisab", .indonesian: "Tidak Mencapai Nisab", .malay: "Tidak Melepasi Nisab"],
        "zakat_due": [.english: "Zakat Maal Due", .indonesian: "Zakat Mal Wajib", .malay: "Zakat Mal Wajib"],
        "zakat_fitrah_specs": [.english: "Fitrah Specifications", .indonesian: "Spesifikasi Fitrah", .malay: "Spesifikasi Fitrah"],
        "zakat_family_members": [.english: "Family Members", .indonesian: "Anggota Keluarga", .malay: "Ahli Keluarga"],
        "zakat_staple_price": [.english: "Staple Price / kg", .indonesian: "Harga Makanan Pokok / kg", .malay: "Harga Makanan Pokok / kg"],
        "zakat_staple_weight": [.english: "Staple Weight / Person", .indonesian: "Berat Staples / Orang", .malay: "Berat Staples / Orang"],
        "zakat_fitrah_results": [.english: "Fitrah Results", .indonesian: "Hasil Zakat Fitrah", .malay: "Keputusan Zakat Fitrah"],
        "zakat_total_staple": [.english: "Total Staple Required", .indonesian: "Total Staples Dibutuhkan", .malay: "Jumlah Staples Diperlukan"],
        "zakat_fitrah_due": [.english: "Total Zakat Fitrah Due", .indonesian: "Zakat Fitrah Wajib", .malay: "Zakat Fitrah Wajib"],

        // Dhikr Tasbih
        "dhikr_title": [.english: "Dhikr", .indonesian: "Dzikir", .malay: "Zikir"],
        "dhikr_subtitle": [.english: "Premium digital tasbih", .indonesian: "Tasbih digital premium", .malay: "Tasbih digital premium"],

        // Doa & Zikir
        "dzikir_start": [.english: "Start Dhikr", .indonesian: "Mulai Zikir", .malay: "Mula Zikir"],
        "dzikir_empty": [.english: "Dhikr is empty", .indonesian: "Zikir kosong", .malay: "Zikir kosong"],
        "dzikir_progress_format": [.english: "Dhikr %d of %d", .indonesian: "Dzikir %d dari %d", .malay: "Zikir %d dari %d"],
        "dzikir_completed_desc": [.english: "You have successfully completed the entire dhikr series. May Allah accept your worship.", .indonesian: "Anda telah menyelesaikan seluruh rangkaian zikir dengan baik. Semoga Allah menerima amal ibadah Anda.", .malay: "Anda telah menyelesaikan seluruh rangkaian zikir dengan baik. Semoga Allah menerima amal ibadah anda."],
        "dzikir_repeat": [.english: "Repeat Dhikr", .indonesian: "Ulangi Zikir", .malay: "Ulangi Zikir"],
        "dzikir_back_to_menu": [.english: "Back to Menu", .indonesian: "Kembali ke Menu", .malay: "Kembali ke Menu"],

        // Manzil Protection
        "manzil_quranic_protection": [.english: "Quranic Protection", .indonesian: "Perlindungan Al-Quran", .malay: "Perlindungan Al-Quran"],
        "manzil_quranic_protection_sub": [.english: "Selected verses for protection from sihr, jinn, and harm.", .indonesian: "Ayat-ayat pilihan untuk perlindungan dari sihir, jin, dan bahaya.", .malay: "Ayat-ayat pilihan untuk perlindungan daripada sihir, jin, dan bahaya."],
        "manzil_about": [.english: "About Manzil Al-Quran", .indonesian: "Tentang Manzil Al-Quran", .malay: "Tentang Manzil Al-Quran"],
        "manzil_about_sub": [.english: "Definition, 7-day division & practice guide", .indonesian: "Definisi, pembagian 7 hari & panduan amalan", .malay: "Definisi, pembahagian 7 hari & panduan amalan"],
        "manzil_what_is": [.english: "What is Manzil?", .indonesian: "Apa itu Manzil?", .malay: "Apa itu Manzil?"],
        "manzil_what_is_desc": [.english: "Manzil (Arabic: منزل) is a system for dividing the recitation of the Quran to facilitate completing (khatam) the Quran over seven days (one week). This tradition is widely practiced in South Asian Muslim communities.\n\nNote: \"Manzil\" here refers to the 7-part Quran division for khatam, and is different from the protection verses (Manzil ruqyah) compiled by Maulana Zakariyya Kandhlawi. This section in the app covers the protection verses.", .indonesian: "Manzil (Arab: منزل) adalah sistem pembagian bacaan Al-Quran untuk memudahkan khatam Al-Quran dalam tujuh hari (satu minggu). Tradisi ini banyak diamalkan di kalangan umat Islam.\n\nCatatan: \"Manzil\" di sini mengacu pada pembagian Al-Quran 7 bagian untuk khatam, dan berbeda dengan ayat-ayat ruqyah (Manzil ruqyah) yang disusun oleh Maulana Zakariyya Kandhlawi. Bagian ini membahas tentang ayat perlindungan.", .malay: "Manzil (Arab: منزل) ialah sistem pembahagian bacaan Al-Quran untuk memudahkan khatam Al-Quran dalam tujuh hari (satu minggu). Tradisi ini banyak diamalkan di kalangan umat Islam.\n\nNota: \"Manzil\" di sini merujuk kepada pembahagian Al-Quran 7 bahagian untuk khatam, dan berbeza dengan ayat-ayat ruqyah (Manzil ruqyah) yang disusun oleh Maulana Zakariyya Kandhlawi. Bahagian ini membincangkan tentang ayat perlindungan."],
        "manzil_fami": [.english: "Fami bi Syauqin (فَمِي بِشَوْقٍ)", .indonesian: "Fami bi Syauqin (فَمِي بِشَوْقٍ)", .malay: "Fami bi Syauqin (فَمِي بِشَوْقٍ)"],
        "manzil_fami_desc": [.english: "A mnemonic phrase meaning \"My mouth longs to recite (the Quran)\". The 7 letters — ف م ي ب ش و ق — are the first letters of the surah that begins each of the 7 Manzils: Al-Fatihah, Al-Ma'idah, Yunus, Al-Isra', Asy-Syu'ara, Ash-Shaffat, and Qaf.", .indonesian: "Ungkapan mnemonik yang berarti \"Mulutku rindu membaca (Al-Quran)\". Ke-7 huruf tersebut — ف م ي ب ش w ق — adalah huruf pertama dari surah yang memulai masing-masing dari 7 Manzil: Al-Fatihah, Al-Ma'idah, Yunus, Al-Isra', Asy-Syu'ara, Ash-Shaffat, dan Qaf.", .malay: "Ungkapan mnemonik yang bermaksud \"Mulutku rindu membaca (Al-Quran)\". Ke-7 huruf tersebut — ف م ي b ش w q — adalah huruf pertama dari surah yang memulakan masing-masing daripada 7 Manzil: Al-Fatihah, Al-Ma'idah, Yunus, Al-Isra', Asy-Syu'ara, Ash-Shaffat, dan Qaf."],
        "manzil_7day": [.english: "7-Day Manzil Division", .indonesian: "Pembagian Manzil 7 Hari", .malay: "Pembahagian Manzil 7 Hari"],
        "manzil_column": [.english: "Manzil", .indonesian: "Manzil", .malay: "Manzil"],
        "manzil_surah_range": [.english: "Surah Range", .indonesian: "Cakupan Surah", .malay: "Cakupan Surah"],
        "manzil_how_to": [.english: "How to Practice", .indonesian: "Cara Mengamalkan", .malay: "Cara Mengamalkan"],
        "manzil_how_to_desc": [.english: "Each day, recite one Manzil in sequence from Monday to Sunday, completing the entire Quran in one week. You may recite it in one sitting or spread it across multiple sessions during the day.", .indonesian: "Setiap hari, bacalah satu Manzil secara berurutan dari Senin hingga Minggu, untuk menyelesaikan seluruh Al-Quran dalam satu minggu. Anda dapat membacanya sekaligus atau membaginya dalam beberapa sesi dalam sehari.", .malay: "Setiap hari, bacalah satu Manzil secara berurutan dari Isnin hingga Ahad, untuk menyelesaikan seluruh Al-Quran dalam satu minggu. Anda boleh membacanya sekaligus atau membaginya dalam beberapa sesi dalam sehari."],
        "manzil_virtues": [.english: "Virtues & Benefits", .indonesian: "Keutamaan & Manfaat", .malay: "Keutamaan & Manfaat"],
        
        "manzil_benefit_1": [.english: "Enables regular completion (khatam) of the Quran — once per week.", .indonesian: "Memungkinkan khatam Al-Quran secara teratur — seminggu sekali."],
        "manzil_benefit_2": [.english: "Builds a strong, consistent relationship with the Book of Allah.", .indonesian: "Membangun hubungan yang kuat dan konsisten dengan Kitabullah."],
        "manzil_benefit_3": [.english: "Reciting the entire Quran regularly earns great reward and forgiveness.", .indonesian: "Membaca seluruh Al-Quran secara teratur mendatangkan pahala dan ampunan besar."],
        "manzil_benefit_4": [.english: "Encourages daily reflection on different parts of the Quran.", .indonesian: "Mendorong tadabur harian pada berbagai bagian Al-Quran."],
        "manzil_benefit_5": [.english: "A structured approach recommended by classical scholars and passed down through generations.", .indonesian: "Pendekatan terstruktur yang direkomendasikan oleh para ulama terdahulu."],
        
        "manzil_sec_1_desc": [.english: "Begin Manzil with Al-Fatihah — the greatest surah, recited in every rakah. A cure and protection.", .indonesian: "Mulai Manzil dengan Al-Fatihah — surah teragung, dibaca di setiap rakaat. Penawar dan perlindungan."],
        "manzil_sec_2_desc": [.english: "Continue with the opening of Al-Baqarah — guidance for the God-conscious and the path to success.", .indonesian: "Lanjutkan dengan awal Al-Baqarah — petunjuk bagi orang yang bertakwa dan jalan menuju kesuksesan."],
        "manzil_sec_3_desc": [.english: "Your God is One — there is no deity but Him, the Most Gracious, the Most Merciful.", .indonesian: "Tuhanmu adalah Tuhan Yang Maha Esa — tidak ada tuhan selain Dia, Yang Maha Pengasih lagi Maha Penyayang."],
        "manzil_sec_4_desc": [.english: "The greatest verse in the Quran — a fortress of protection. Whoever recites it at night remains under Allah's protection until morning.", .indonesian: "Ayat paling agung dalam Al-Quran — benteng perlindungan. Barangsiapa membacanya di malam hari akan senantiasa dalam penjagaan Allah hingga pagi."],
        "manzil_sec_5_desc": [.english: "There is no compulsion in religion — truth has become clear from falsehood.", .indonesian: "Tidak ada paksaan dalam menganut agama — kebenaran telah tampak jelas dari kesesatan."],
        "manzil_sec_6_desc": [.english: "Allah is the Protector of the believers, bringing them from darkness into light.", .indonesian: "Allah adalah Pelindung bagi orang-orang yang beriman, mengeluarkan mereka dari kegelapan menuju cahaya."],
        "manzil_sec_7_desc": [.english: "To Allah belongs all that is in the heavens and earth — He will call you to account for what is in your hearts.", .indonesian: "Milik Allah segala apa yang ada di langit dan di bumi — Dia akan memperhitungkan apa yang ada di dalam hatimu."],
        "manzil_sec_8_desc": [.english: "The Messenger and believers have faith in what was revealed — we hear and we obey, seeking Your forgiveness.", .indonesian: "Rasul dan orang-orang mukmin beriman kepada apa yang diturunkan — kami dengar dan kami taat, memohon ampunan-Mu."],
        "manzil_sec_9_desc": [.english: "Allah does not burden a soul beyond its capacity — the closing supplication of Al-Baqarah for forgiveness and help.", .indonesian: "Allah tidak membebani seseorang melainkan sesuai kesanggupannya — doa penutup Al-Baqarah memohon ampunan dan pertolongan."],
        "manzil_sec_10_desc": [.english: "Allah testifies that there is no deity but Him — the Almighty, the All-Wise.", .indonesian: "Allah menyatakan bahwa tidak ada tuhan selain Dia — Yang Maha Perkasa lagi Maha Bijaksana."],
        "manzil_sec_11_desc": [.english: "Say: O Allah, Owner of sovereignty — You give honour and power to whom You will.", .indonesian: "Katakanlah: Wahai Allah Pemilik kekuasaan — Engkau muliakan siapa yang Engkau kehendaki."],
        "manzil_sec_12_desc": [.english: "You cause the night to enter the day and bring the living from the dead — You provide for whom You will without measure.", .indonesian: "Engkau masukkan malam ke dalam siang dan Engkau keluarkan yang hidup dari yang mati — Engkau beri rezeki tanpa batas."],
        "manzil_sec_13_desc": [.english: "Your Lord created the heavens and earth in six days — call upon Him humbly and in secret.", .indonesian: "Tuhanmu menciptakan langit dan bumi dalam enam masa — berdoalah kepada-Nya dengan rendah hati dan suara lembut."],
        "manzil_sec_14_desc": [.english: "Call upon Allah or Ar-Rahman — to Him belong the Most Beautiful Names. Praise be to Him who has no son nor partner.", .indonesian: "Serulah Allah atau Ar-Rahman — milik-Nya Nama-Nama yang Terbaik. Segala puji bagi Allah yang tidak mempunyai anak/sekutu."],
        "manzil_sec_15_desc": [.english: "Were you created without purpose? Exalted is Allah, the True King — seek His forgiveness and mercy.", .indonesian: "Apakah kamu mengira bahwa kamu diciptakan sia-sia? Maha Tinggi Allah, Raja Yang Sebenarnya — mohonlah ampunan dan rahmat-Nya."],
        "manzil_sec_16_desc": [.english: "By the angels ranged in rows — your God is One, Lord of the heavens and the earth.", .indonesian: "Demi (rombongan malaikat) yang berbaris bersaf-saf — Tuhanmu benar-benar Esa, Tuhan langit dan bumi."],
        "manzil_sec_17_desc": [.english: "O assembly of jinn and men — none can escape Allah's authority. Which of your Lord's favours will you deny?", .indonesian: "Wahai golongan jin dan manusia — kamu tidak dapat menembus penjuru langit melainkan dengan kekuatan. Nikmat Tuhan mana yang kamu dustakan?"],
        "manzil_sec_18_desc": [.english: "If this Quran were sent upon a mountain, it would crumble — He is Allah, the Creator, the Bestower of Forms, the Most Beautiful Names.", .indonesian: "Sekiranya Kami turunkan Al-Quran ini kepada gunung, niscaya ia tunduk pecah berserakan — Dialah Allah Yang Menciptakan, Maha Indah Nama-Nya."],
        "manzil_sec_19_desc": [.english: "A group of jinn heard the Quran, believed, and declared their faith — our Lord has no spouse or child.", .indonesian: "Sekelompok jin mendengarkan Al-Quran lalu mereka beriman — Tuhan kami tidak beristri dan tidak beranak."],
        "manzil_sec_20_desc": [.english: "A declaration of disavowal from disbelief — to you your religion, to me mine.", .indonesian: "Pernyataan berlepas diri dari kekafiran — bagimu agamamu, bagiku agamaku."],
        "manzil_sec_21_desc": [.english: "The essence of Tawheed — He is Allah, the One, the Eternal Refuge, who begets not nor is begotten.", .indonesian: "Inti dari Tauhid — Dialah Allah Yang Maha Esa, tempat bergantung, tidak melahirkan dan tidak dilahirkan."],
        "manzil_sec_22_desc": [.english: "Seek refuge with the Lord of daybreak from the evil of creation, darkness, sorcery, and envy.", .indonesian: "Mohon perlindungan kepada Tuhan yang menguasai subuh dari kejahatan makhluk, kegelapan, tukang sihir, dan pendengki."],
        "manzil_sec_23_desc": [.english: "Seek refuge with the Lord of mankind, the King of mankind, from the whisperer who withdraws.", .indonesian: "Mohon perlindungan kepada Tuhan manusia, Raja manusia, dari kejahatan bisikan syetan yang bersembunyi."],

        // Qiyam Tracker
        "qiyam_tracker_subtitle": [.english: "Night prayer tracker & guide", .indonesian: "Pencatat & panduan shalat malam", .malay: "Pencatat & panduan solat malam"],
        "qiyam_tab_tracker": [.english: "Tracker", .indonesian: "Jurnal", .malay: "Diari"],
        "qiyam_tab_readings": [.english: "Readings", .indonesian: "Bacaan", .malay: "Bacaan"],
        "qiyam_tracker_desc": [.english: "The last third of the night is a blessed time for dua and extra rakah. Log here when you stand for qiyam tonight.", .indonesian: "Sepertiga malam terakhir adalah waktu utama untuk berdoa dan shalat malam. Catat di sini ketika Anda melaksanakan qiyam malam ini.", .malay: "Sepertiga malam terakhir ialah waktu utama untuk berdoa dan solat malam. Catat di sini apabila anda melaksanakan qiyam malam ini."],
        "qiyam_prayed_tonight": [.english: "Prayed qiyam tonight", .indonesian: "Sudah shalat malam ini", .malay: "Sudah solat malam ini"],
        "qiyam_private_tracker": [.english: "Private tracker", .indonesian: "Jurnal pribadi luring", .malay: "Jurnal peribadi luar talian"],
        "qiyam_readings_desc": [.english: "Expand each section for Arabic text, transliteration, and step-by-step guidance for tahajud / qiyam.", .indonesian: "Buka setiap bagian untuk melihat teks Arab, transliterasi, dan panduan langkah demi langkah untuk tahajud / qiyam.", .malay: "Buka setiap bahagian untuk melihat teks Arab, transliterasi, dan panduan langkah demi langkah untuk tahajud / qiyam."],
        "qiyam_what_is": [.english: "Qiyam is voluntary night prayer — often called tahajud when prayed after sleep.", .indonesian: "Qiyamul lail adalah shalat malam sunnah — sering disebut tahajud jika dikerjakan setelah tidur.", .malay: "Qiyamullail ialah solat malam sunat — sering dipanggil tahajjud jika dikerjakan selepas tidur."],

        // Faraidh Additional
        "faraidh_tab_form": [.english: "Form", .indonesian: "Formulir", .malay: "Borang"],
        "faraidh_tab_shares": [.english: "Shares", .indonesian: "Pembagian", .malay: "Bahagian"],
        "faraidh_tab_proofs": [.english: "Proofs", .indonesian: "Silsilah", .malay: "Silsilah"],
        "faraidh_shafii": [.english: "Shafi'i", .indonesian: "Syafi'i", .malay: "Syafi'i"],
        "faraidh_hanafi": [.english: "Hanafi", .indonesian: "Hanafi", .malay: "Hanafi"],
        "faraidh_maliki": [.english: "Maliki", .indonesian: "Maliki", .malay: "Maliki"],
        "faraidh_hanbali": [.english: "Hanbali", .indonesian: "Hambali", .malay: "Hambali"],
        "faraidh_estate_summary": [.english: "Estate Summary", .indonesian: "Ringkasan Harta", .malay: "Ringkasan Harta"],
        "faraidh_net_estate": [.english: "Net Inheritable Estate", .indonesian: "Harta Bersih Waris", .malay: "Harta Bersih Waris"],
        "faraidh_distributions": [.english: "Heir Distributions", .indonesian: "Pembagian Ahli Waris", .malay: "Pembahagian Ahli Waris"],
        "faraidh_fallback_baitulmal": [.english: "No active inheriting heirs. Total will fallback to Baitul Mal.", .indonesian: "Tidak ada ahli waris yang berhak menerima. Harta diserahkan ke Baitul Mal.", .malay: "Tiada ahli waris yang berhak menerima. Harta diserahkan ke Baitul Mal."],
        "faraidh_aul": [.english: "Aul Deficit Adjustment", .indonesian: "Penyesuaian Defisit Aul", .malay: "Penyesuaian Defisit Aul"],
        "faraidh_radd": [.english: "Radd Surplus Adjustment", .indonesian: "Penyesuaian Surplus Radd", .malay: "Penyesuaian Surplus Radd"],
        "faraidh_blocked_heirs": [.english: "Blocked / Excluded Heirs", .indonesian: "Ahli Waris Terhijab (Terhalang)", .malay: "Ahli Waris Terhijab (Terhalang)"],
        "faraidh_no_blocked": [.english: "No heirs were blocked or excluded.", .indonesian: "Tidak ada ahli waris yang terhalang.", .malay: "Tiada ahli waris yang terhalang."],
        "faraidh_silsilah": [.english: "Kinship Hierarchy (Silsilah)", .indonesian: "Silsilah Kekerabatan", .malay: "Silsilah Kekerabatan"],
        "faraidh_gross_assets": [.english: "Gross Assets", .indonesian: "Aset Kotor", .malay: "Aset Kasar"],
        "faraidh_case_format": [.english: "Detected Case: %@", .indonesian: "Kasus Terdeteksi: %@", .malay: "Kes Terkesan: %@"],
        "faraidh_heir_count_singular": [.english: "Person", .indonesian: "Orang", .malay: "Orang"],
        "faraidh_heir_count_plural": [.english: "People", .indonesian: "Orang", .malay: "Orang"],
        "faraidh_type_asabah": [.english: "Asabah (Residue)", .indonesian: "Asabah (Sisa)", .malay: "Asabah (Baki)"],
        "faraidh_type_fixed": [.english: "Fixed Share", .indonesian: "Bagian Tetap", .malay: "Bahagian Tetap"],
        "faraidh_aul_desc": [.english: "Deficit in fixed shares resolved by increasing the denominator.", .indonesian: "Kekurangan bagian tetap diselesaikan dengan menaikkan penyebut.", .malay: "Kekurangan bahagian tetap diselesaikan dengan menaikkan penyebut."],
        "faraidh_radd_desc": [.english: "Surplus residue distributed back to eligible Quranic heirs.", .indonesian: "Kelebihan baki dibagikan kembali kepada ahli waris Dzawil Furud.", .malay: "Kelebihan baki dibahagikan kembali kepada ahli waris Dzawil Furud."],
        
        // Faraidh fields & heirs
        "faraidh_cash": [.english: "Cash/Savings", .indonesian: "Uang Tunai/Tabungan", .malay: "Wang Tunai/Simpanan"],
        "faraidh_gold": [.english: "Gold Assets", .indonesian: "Aset Emas", .malay: "Aset Emas"],
        "faraidh_property": [.english: "Property Value", .indonesian: "Nilai Properti", .malay: "Nilai Hartanah"],
        "faraidh_business": [.english: "Business Assets", .indonesian: "Aset Bisnis", .malay: "Aset Perniagaan"],
        "faraidh_other": [.english: "Other Assets", .indonesian: "Aset Lainnya", .malay: "Aset Lain-lain"],
        "faraidh_funeral": [.english: "Funeral Costs", .indonesian: "Biaya Pengurusan Jenazah", .malay: "Kos Pengurusan Jenazah"],
        "faraidh_debts": [.english: "Debts / Liabilities", .indonesian: "Utang / Kewajiban", .malay: "Hutang / Liabiliti"],
        "faraidh_zakat": [.english: "Unpaid Zakat", .indonesian: "Zakat Belum Dibayar", .malay: "Zakat Belum Dibayar"],
        "faraidh_wasiat": [.english: "Bequest (Wasiat)", .indonesian: "Wasiat", .malay: "Wasiat"],
        
        "faraidh_heir_husband": [.english: "Husband", .indonesian: "Suami", .malay: "Suami"],
        "faraidh_heir_wives": [.english: "Wives", .indonesian: "Istri-istri", .malay: "Isteri-isteri"],
        "faraidh_heir_father": [.english: "Father", .indonesian: "Ayah", .malay: "Bapa"],
        "faraidh_heir_mother": [.english: "Mother", .indonesian: "Ibu", .malay: "Ibu"],
        "faraidh_heir_grandfather": [.english: "Grandfather", .indonesian: "Kakek", .malay: "Datuk"],
        "faraidh_heir_sons": [.english: "Sons", .indonesian: "Anak Laki-laki", .malay: "Anak Lelaki"],
        "faraidh_heir_daughters": [.english: "Daughters", .indonesian: "Anak Perempuan", .malay: "Anak Perempuan"],
        "faraidh_heir_grandsons": [.english: "Grandsons (via Son)", .indonesian: "Cucu Laki-laki (dari Anak Laki)", .malay: "Cucu Lelaki (daripada Anak Lelaki)"],
        "faraidh_heir_granddaughters": [.english: "Granddaughters (via Son)", .indonesian: "Cucu Perempuan (dari Anak Laki)", .malay: "Cucu Perempuan (daripada Anak Lelaki)"],
        "faraidh_heir_full_brothers": [.english: "Full Brothers", .indonesian: "Saudara Kandung Laki-laki", .malay: "Saudara Kandung Lelaki"],
        "faraidh_heir_full_sisters": [.english: "Full Sisters", .indonesian: "Saudara Kandung Perempuan", .malay: "Saudara Kandung Perempuan"],
        "faraidh_heir_paternal_brothers": [.english: "Paternal Brothers", .indonesian: "Saudara Seayah Laki-laki", .malay: "Saudara Sebapa Lelaki"],
        "faraidh_heir_paternal_sisters": [.english: "Paternal Sisters", .indonesian: "Saudara Seayah Perempuan", .malay: "Saudara Sebapa Perempuan"],
        "faraidh_heir_maternal_brothers": [.english: "Maternal Brothers", .indonesian: "Saudara Seibu Laki-laki", .malay: "Saudara Seibu Lelaki"],
        "faraidh_heir_maternal_sisters": [.english: "Maternal Sisters", .indonesian: "Saudara Seibu Perempuan", .malay: "Saudara Seibu Perempuan"],
        
        "faraidh_heir_maternal_sibling": [.english: "Maternal Sibling", .indonesian: "Saudara Seibu", .malay: "Saudara Seibu"],
        "faraidh_heir_baitul_mal_or_excluded": [.english: "Baitul Mal / Excluded Kindred", .indonesian: "Baitul Mal / Ahli Waris Terhalang", .malay: "Baitul Mal / Ahli Waris Terhalang"],
        "faraidh_heir_unborn_fetus": [.english: "Unborn Fetus", .indonesian: "Janin dalam Kandungan", .malay: "Janin dalam Kandungan"],
        "faraidh_deceased": [.english: "Deceased", .indonesian: "Pewaris", .malay: "Pewaris"],
        "faraidh_indiv_share": [.english: "Indiv Share", .indonesian: "Bagian Per Orang", .malay: "Bahagian Per Orang"],
        
        "faraidh_reason_by_son": [.english: "Blocked by Son", .indonesian: "Terhalang oleh Anak Laki-laki", .malay: "Terhalang oleh Anak Lelaki"],
        "faraidh_reason_by_children": [.english: "Blocked by Child", .indonesian: "Terhalang oleh Anak", .malay: "Terhalang oleh Anak"],
        "faraidh_reason_by_father": [.english: "Blocked by Father", .indonesian: "Terhalang oleh Ayah", .malay: "Terhalang oleh Bapa"],
        "faraidh_reason_by_grandfather": [.english: "Blocked by Grandfather", .indonesian: "Terhalang oleh Kakek", .malay: "Terhalang oleh Datuk"],
        "faraidh_reason_excluded": [.english: "Excluded", .indonesian: "Terhalang", .malay: "Terhalang"],
        "faraidh_reason_gender_mismatch": [.english: "Gender Mismatch", .indonesian: "Ketidaksesuaian Jantina", .malay: "Ketidaksesuaian Jantina"],
        "faraidh_reason_no_remainder": [.english: "No Share Remainder", .indonesian: "Tidak Ada Sisa Bagian", .malay: "Tiada Baki Bahagian"],
        "faraidh_reason_out_of_wedlock": [.english: "Born Out of Wedlock", .indonesian: "Lahir di Luar Nikah", .malay: "Lahir Luar Nikah"],
        "faraidh_reason_homicide": [.english: "Excluded by Homicide", .indonesian: "Terhalang karena Membunuh", .malay: "Terhalang kerana Membunuh"],
        "faraidh_reason_religion": [.english: "Difference of Religion", .indonesian: "Perbedaan Agama", .malay: "Perbezaan Agama"],
        "faraidh_reason_simultaneous": [.english: "Simultaneous Death", .indonesian: "Meninggal Bersamaan", .malay: "Meninggal Bersama"],
        
        "faraidh_case_minbariyah": [.english: "Al-Minbariyah", .indonesian: "Al-Minbariyah", .malay: "Al-Minbariyah"],
        "faraidh_case_akdariyah": [.english: "Al-Akdariyah", .indonesian: "Al-Akdariyah", .malay: "Al-Akdariyah"],
        "faraidh_case_marwaniyah": [.english: "Al-Marwaniyah", .indonesian: "Al-Marwaniyah", .malay: "Al-Marwaniyah"],
        "faraidh_case_umariyatain": [.english: "Al-Umariyatain", .indonesian: "Al-Umariyatain", .malay: "Al-Umariyatain"],
        
        // Qiyam Additional
        "qiyam_cat_prep": [.english: "Preparation", .indonesian: "Persiapan", .malay: "Persiapan"],
        "qiyam_cat_prayer": [.english: "Prayer (2 rakah pairs)", .indonesian: "Shalat (Kelipatan 2 Rakaat)", .malay: "Solat (Kelipatan 2 Rakaat)"],
        "qiyam_cat_witr": [.english: "Witr", .indonesian: "Witir", .malay: "Witir"],
        "qiyam_cat_closing": [.english: "After prayer", .indonesian: "Setelah Shalat", .malay: "Selepas Solat"],
        "qiyam_streak": [.english: "Day streak", .indonesian: "Streak Hari", .malay: "Streak Hari"],
        "qiyam_this_month": [.english: "This month", .indonesian: "Bulan Ini", .malay: "Bulan Ini"],
        "qiyam_last_7_days": [.english: "Last 7 days", .indonesian: "7 Hari Terakhir", .malay: "7 Hari Terakhir"],
        
        "tahajud_when_title": [.english: "Best time — last third of night", .indonesian: "Waktu terbaik — sepertiga malam terakhir", .malay: "Waktu terbaik — sepertiga malam terakhir"],
        "tahajud_when_body": [.english: "Sleep with intention to wake for tahajud. The last third of the night (between Isha and Fajr) is especially blessed. Even two rakah before Fajr count as tahajud.", .indonesian: "Tidurlah dengan niat untuk bangun tahajud. Sepertiga malam terakhir (antara Isya dan Subuh) adalah waktu yang sangat berkah. Bahkan dua rakaat sebelum Subuh sudah terhitung tahajud.", .malay: "Tidurlah dengan niat untuk bangun tahajud. Sepertiga malam terakhir (antara Isyak dan Subuh) adalah waktu yang sangat berkat. Malah dua rakaat sebelum Subuh sudah terhitung tahajud."],
        "tahajud_niat_title": [.english: "Intention (niyyah)", .indonesian: "Niat", .malay: "Niat"],
        "tahajud_niat_body": [.english: "Make intention in your heart before takbir. Example: I intend to pray sunnah tahajud for Allah.", .indonesian: "Lafalkan atau mantapkan niat di dalam hati sebelum takbir. Contoh: Saya berniat shalat sunnah tahajud karena Allah.", .malay: "Lafazkan atau mantapkan niat di dalam hati sebelum takbir. Contoh: Saya berniat solat sunat tahajjud kerana Allah."],
        "tahajud_takbir_title": [.english: "Takbiratul ihram", .indonesian: "Takbiratul Ihram", .malay: "Takbiratul Ihram"],
        "tahajud_takbir_body": [.english: "Raise hands and say Allahu Akbar to begin each rakah pair. Face the qibla with wudu.", .indonesian: "Angkat tangan dan ucapkan Allahu Akbar untuk memulai setiap dua rakaat. Menghadap kiblat dengan keadaan suci/berwudhu.", .malay: "Angkat tangan dan ucapkan Allahu Akbar untuk memulakan setiap dua rakaat. Menghadap kiblat dengan keadaan suci/berwuduk."],
        "tahajud_iftitah_title": [.english: "Opening supplication (optional)", .indonesian: "Doa Iftitah (Sunnah)", .malay: "Doa Iftitah (Sunat)"],
        "tahajud_iftitah_body": [.english: "After takbir, you may recite the opening dua before Al-Fatihah in the first rakah.", .indonesian: "Setelah takbir, Anda disunnahkan membaca doa iftitah sebelum membaca Al-Fatihah pada rakaat pertama.", .malay: "Selepas takbir, anda disunatkan membaca doa iftitah sebelum membaca Al-Fatihah pada rakaat pertama."],
        "tahajud_fatihah_title": [.english: "Al-Fatihah", .indonesian: "Al-Fatihah", .malay: "Al-Fatihah"],
        "tahajud_fatihah_body": [.english: "Recite Al-Fatihah in every rakah, then a short surah or a few verses in the first two rakah of each pair.", .indonesian: "Membaca surat Al-Fatihah di setiap rakaat, diikuti oleh surah pendek atau ayat Al-Quran pada rakaat pertama dan kedua.", .malay: "Membaca surah Al-Fatihah di setiap rakaat, diikuti oleh surah pendek atau ayat Al-Quran pada rakaat pertama dan kedua."],
        "tahajud_surah_title": [.english: "Short surahs (examples)", .indonesian: "Pilihan Surah Pendek", .malay: "Pilihan Surah Pendek"],
        "tahajud_surah_body": [.english: "Common choices: Al-Ikhlas, Al-Falaq, An-Nas, Al-Kafirun, or any surah you know. Tahajud is prayed in pairs of two rakah — say salam after every two.", .indonesian: "Pilihan umum: Al-Ikhlas, Al-Falaq, An-Nas, Al-Kafirun, atau surah apa pun yang Anda hafal. Shalat tahajud dikerjakan kelipatan 2 rakaat — lakukan salam setelah tiap 2 rakaat.", .malay: "Pilihan umum: Al-Ikhlas, Al-Falaq, An-Nas, Al-Kafirun, atau surah apa-apa yang anda hafal. Solat tahajjud dikerjakan kelipatan 2 rakaat — lakukan salam selepas setiap 2 rakaat."],
        "tahajud_ruku_title": [.english: "Ruku", .indonesian: "Rukuk", .malay: "Rukuk"],
        "tahajud_ruku_body": [.english: "Bow with back straight, hands on knees. Say tasbih at least 3 times.", .indonesian: "Membungkuk dengan punggung lurus, tangan memegang lutut. Membaca tasbih rukuk minimal 3 kali.", .malay: "Membongkok dengan punggung lurus, tangan memegang lutut. Membaca tasbih rukuk sekurang-kurangnya 3 kali."],
        "tahajud_sujud_title": [.english: "Sujud", .indonesian: "Sujud", .malay: "Sujud"],
        "tahajud_sujud_body": [.english: "Prostrate with forehead, nose, hands, knees, and toes on the ground. Say tasbih at least 3 times per sajdah.", .indonesian: "Bersujud dengan dahi, hidung, kedua telapak tangan, lutut, dan jari kaki menempel lantai. Membaca tasbih sujud minimal 3 kali.", .malay: "Bersujud dengan dahi, hidung, kedua tapak tangan, lutut, dan jari kaki menempel lantai. Membaca tasbih sujud sekurang-kurangnya 3 kali."],
        "tahajud_witr_title": [.english: "Witr (closing odd prayer)", .indonesian: "Shalat Witir (Penutup Ganjil)", .malay: "Solat Witir (Penutup Ganjil)"],
        "tahajud_witr_body": [.english: "End the night with witr — minimum 1 rakah, commonly 3. In the final rakah, raise hands for qunut before ruku (per your madhab). After witr, do not pray more sunnah.", .indonesian: "Tutuplah shalat malam Anda dengan witir — minimal 1 rakaat, umumnya 3 rakaat. Setelah witir selesai, tidak diperbolehkan lagi mengerjakan shalat sunnah lainnya malam itu.", .malay: "Tutuplah solat malam anda dengan witir — minimal 1 rakaat, biasanya 3 rakaat. Selepas witir selesai, tidak dibenarkan lagi mengerjakan solat sunat yang lain malam itu."],
        "tahajud_qunut_title": [.english: "Qunut supplication (witr)", .indonesian: "Doa Qunut Witir", .malay: "Doa Qunut Witir"],
        "tahajud_qunut_body": [.english: "Recite qunut in the last rakah of witr while standing, before ruku. Many scholars allow a shorter dua if the full text is difficult to memorize.", .indonesian: "Membaca doa qunut pada rakaat terakhir witir saat berdiri tegak sebelum rukuk. Diperbolehkan membaca doa yang lebih pendek jika belum hafal qunut penuh.", .malay: "Membaca doa qunut pada rakaat terakhir witir semasa berdiri tegak sebelum rukuk. Dibenarkan membaca doa yang lebih pendek jika belum hafal qunut penuh."],
        "tahajud_dhikr_title": [.english: "Dhikr after prayer", .indonesian: "Dzikir Setelah Shalat", .malay: "Zikir Selepas Solat"],
        "tahajud_dhikr_body": [.english: "After salam: Astaghfirullah ×3, Allahumma antas salam…, then 33× SubhanAllah, 33× Alhamdulillah, 34× Allahu Akbar (or combined to 100).", .indonesian: "Setelah salam: Membaca istighfar 3 kali, Allahumma antas salam..., dilanjutkan tasbih 33 kali, tahmid 33 kali, dan takbir 34 kali.", .malay: "Selepas salam: Membaca istighfar 3 kali, Allahumma antas salam..., dilanjutkan tasbih 33 kali, tahmid 33 kali, dan takbir 34 kali."],
        "tahajud_dua_title": [.english: "Personal dua", .indonesian: "Doa Pribadi", .malay: "Doa Peribadi"],
        "tahajud_dua_body": [.english: "The last third of the night is when Allah descends (in a manner befitting Him) and answers dua. Ask for forgiveness, guidance, family, and the ummah. Speak from the heart in any language.", .indonesian: "Sepertiga malam terakhir adalah waktu mustajab di mana Allah mengabulkan doa. Mohonlah ampunan, petunjuk, dan keberkahan dengan bahasa yang Anda pahami langsung dari lubuk hati.", .malay: "Sepertiga malam terakhir ialah waktu mustajab di mana Allah mengabulkan doa. Mohonlah keampunan, petunjuk, dan keberkatan dengan bahasa yang anda fahami langsung dari lubuk hati."],
        
        // Location Settings
        "location_settings_title": [.english: "Location Settings", .indonesian: "Pengaturan Lokasi", .malay: "Tetapan Lokasi"],
        "location_source": [.english: "Location Source", .indonesian: "Sumber Lokasi", .malay: "Sumber Lokasi"],
        "use_gps": [.english: "Use GPS Location", .indonesian: "Gunakan Lokasi GPS", .malay: "Gunakan Lokasi GPS"],
        "set_manually": [.english: "Set Location Manually", .indonesian: "Atur Lokasi Manual", .malay: "Tetapkan Lokasi Manual"],
        "latitude": [.english: "Latitude", .indonesian: "Lintang (Latitude)", .malay: "Latitud"],
        "longitude": [.english: "Longitude", .indonesian: "Bujur (Longitude)", .malay: "Longitud"],
        "city_name": [.english: "City Name", .indonesian: "Nama Kota", .malay: "Nama Bandar"],
        "save_location": [.english: "Save Location", .indonesian: "Simpan Lokasi", .malay: "Simpan Lokasi"],
        "preset_cities": [.english: "Preset Major Cities", .indonesian: "Pilihan Kota Besar", .malay: "Pilihan Bandar Utama"],
        "mecca": [.english: "Mecca", .indonesian: "Mekkah", .malay: "Mekah"],
        "jakarta": [.english: "Jakarta", .indonesian: "Jakarta", .malay: "Jakarta"],
        "kuala_lumpur": [.english: "Kuala Lumpur", .indonesian: "Kuala Lumpur", .malay: "Kuala Lumpur"],
        "singapore": [.english: "Singapore", .indonesian: "Singapura", .malay: "Singapura"],
        "gps_status": [.english: "GPS Status", .indonesian: "Status GPS", .malay: "Status GPS"],
        "gps_active": [.english: "Active (Using GPS)", .indonesian: "Aktif (Menggunakan GPS)", .malay: "Aktif (Menggunakan GPS)"],
        "manual_active": [.english: "Active (Manual Override)", .indonesian: "Aktif (Override Manual)", .malay: "Aktif (Override Manual)"],
        
        // Today & Reflections
        "greeting_morning": [.english: "Good Morning", .indonesian: "Selamat Pagi", .malay: "Selamat Pagi"],
        "greeting_afternoon": [.english: "Good Afternoon", .indonesian: "Selamat Siang", .malay: "Selamat Tengah Hari"],
        "greeting_evening": [.english: "Good Evening", .indonesian: "Selamat Malam", .malay: "Selamat Malam"],
        "locating": [.english: "Locating...", .indonesian: "Mencari Lokasi...", .malay: "Mencari Lokasi..."],
        "loading": [.english: "Loading...", .indonesian: "Memuat...", .malay: "Memuatkan..."],
        "reflection_signin_prompt": [.english: "Sign in to Reflect", .indonesian: "Masuk untuk Menulis Refleksi", .malay: "Log Masuk untuk Menulis Refleksi"],
        "reflection_placeholder": [.english: "Write your reflection here...", .indonesian: "Tulis refleksi Anda di sini...", .malay: "Tulis refleksi anda di sini..."],
        "post_reflection": [.english: "Post Reflection", .indonesian: "Kirim Refleksi", .malay: "Hantar Refleksi"],
        "your_reflection": [.english: "Your Reflection", .indonesian: "Refleksi Anda", .malay: "Refleksi Anda"],
        "revelation_makkah": [.english: "Makkah", .indonesian: "Makkah", .malay: "Mekah"],
        "revelation_madinah": [.english: "Madinah", .indonesian: "Madinah", .malay: "Madinah"],
        
        // Quran Reader & Intro
        "tap_to_begin": [.english: "Tap to begin recitation", .indonesian: "Ketuk untuk memulai tilawah", .malay: "Ketik untuk memula bacaan"],
        "swipe_up_intro": [.english: "Swipe up to continue", .indonesian: "Usap ke atas untuk melanjutkan", .malay: "Sapu ke atas untuk meneruskan"],
        "audio_playing": [.english: "Playing recitation", .indonesian: "Memutar tilawah", .malay: "Memutar bacaan"],
        "audio_paused": [.english: "Recitation paused", .indonesian: "Tilawah dihentikan", .malay: "Bacaan dijeda"]
    ]
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("appLanguageDidChange")
}
