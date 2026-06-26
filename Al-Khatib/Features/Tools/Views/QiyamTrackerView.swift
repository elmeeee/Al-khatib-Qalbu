//
//  QiyamTrackerView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

enum QiyamGuideCategory: String, CaseIterable, Identifiable {
    case preparation = "Preparation"
    case prayer = "Prayer (2 rakah pairs)"
    case witr = "Witr"
    case closing = "After prayer"
    
    var id: String { self.rawValue }
    
    @MainActor
    var localizedName: String {
        switch self {
        case .preparation: return AppLanguageManager.shared.localize("qiyam_cat_prep")
        case .prayer: return AppLanguageManager.shared.localize("qiyam_cat_prayer")
        case .witr: return AppLanguageManager.shared.localize("qiyam_cat_witr")
        case .closing: return AppLanguageManager.shared.localize("qiyam_cat_closing")
        }
    }
}

struct QiyamReading: Identifiable {
    let id: String
    let title: String
    let body: String
    let arabic: String?
    let transliteration: String?
    let category: QiyamGuideCategory
}

struct QiyamTrackerView: View {
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    @State private var selectedTab = 0 // 0: Tracker, 1: Readings
    @State private var loggedTonight = false
    @State private var snapshot: QiyamMonthSnapshot = QiyamMonthSnapshot(nightsThisMonth: 0, nightsLast7Days: 0, streak: 0, isLoggedTonight: false)
    @State private var weekLog: [QiyamDayLog] = []
    
    @State private var expandedReadings: Set<String> = []
        // Readings static list
    private var readings: [QiyamReading] {
        [
            // Preparation
            QiyamReading(
                id: "when",
                title: languageManager.localize("tahajud_when_title"),
                body: languageManager.localize("tahajud_when_body"),
                arabic: nil,
                transliteration: nil,
                category: .preparation
            ),
            QiyamReading(
                id: "niat",
                title: languageManager.localize("tahajud_niat_title"),
                body: languageManager.localize("tahajud_niat_body"),
                arabic: "نَوَيْتُ أَنْ أُصَلِّيَ سُنَّةَ التَّهَجُّدِ لِلَّهِ تَعَالَى",
                transliteration: "Nawaytu an usalliya sunnata at-tahajjudi lillāhi taʿālā",
                category: .preparation
            ),
            // Prayer
            QiyamReading(
                id: "takbir",
                title: languageManager.localize("tahajud_takbir_title"),
                body: languageManager.localize("tahajud_takbir_body"),
                arabic: "اللَّهُ أَكْبَرُ",
                transliteration: "Allāhu akbar",
                category: .prayer
            ),
            QiyamReading(
                id: "iftitah",
                title: languageManager.localize("tahajud_iftitah_title"),
                body: languageManager.localize("tahajud_iftitah_body"),
                arabic: "سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلَا إِلَٰهَ غَيْرُكَ",
                transliteration: "Subḥānaka Allāhumma wa biḥamdika, wa tabāraka smuka, wa taʿālā jadduka, wa lā ilāha ghayruk",
                category: .prayer
            ),
            QiyamReading(
                id: "fatihah",
                title: languageManager.localize("tahajud_fatihah_title"),
                body: languageManager.localize("tahajud_fatihah_body"),
                arabic: nil,
                transliteration: nil,
                category: .prayer
            ),
            QiyamReading(
                id: "surah",
                title: languageManager.localize("tahajud_surah_title"),
                body: languageManager.localize("tahajud_surah_body"),
                arabic: nil,
                transliteration: nil,
                category: .prayer
            ),
            QiyamReading(
                id: "ruku",
                title: languageManager.localize("tahajud_ruku_title"),
                body: languageManager.localize("tahajud_ruku_body"),
                arabic: "سُبْحَان   رَبِّيَ الْعَظِيمِ",
                transliteration: "Subḥāna rabbiyal ʿaẓīm",
                category: .prayer
            ),
            QiyamReading(
                id: "sujud",
                title: languageManager.localize("tahajud_sujud_title"),
                body: languageManager.localize("tahajud_sujud_body"),
                arabic: "سُبْحَانَ رَبِّيَ الْأَعْلَى",
                transliteration: "Subḥāna rabbiyal aʿlā",
                category: .prayer
            ),
            // Witr
            QiyamReading(
                id: "witr",
                title: languageManager.localize("tahajud_witr_title"),
                body: languageManager.localize("tahajud_witr_body"),
                arabic: nil,
                transliteration: nil,
                category: .witr
            ),
            QiyamReading(
                id: "qunut",
                title: languageManager.localize("tahajud_qunut_title"),
                body: languageManager.localize("tahajud_qunut_body"),
                arabic: "اللَّهُمَّ اهْدِنِي فِيمَنْ هَدَيْتَ، وَعَافِنِي فِيمَنْ عَافَيْتَ، وَتَوَلَّنِي فِيمَنْ تَوَلَّيْتَ، وَبَارِكْ لِي فِيمَا أَعْطَيْتَ",
                transliteration: "Allāhumma ihdinī fīman hadayta, wa ʿāfinī fīman ʿāfayta, wa tawallanī fīman tawallayta, wa bārik lī fīmā aʿṭayta",
                category: .witr
            ),
            // Closing
            QiyamReading(
                id: "dhikr_after",
                title: languageManager.localize("tahajud_dhikr_title"),
                body: languageManager.localize("tahajud_dhikr_body"),
                arabic: nil,
                transliteration: nil,
                category: .closing
            ),
            QiyamReading(
                id: "dua",
                title: languageManager.localize("tahajud_dua_title"),
                body: languageManager.localize("tahajud_dua_body"),
                arabic: nil,
                transliteration: nil,
                category: .closing
            )
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                }
                .accessibilityLabel("Back")
                
                Spacer()
                
                VStack(spacing: 2) {
                    Text(languageManager.localize("tool_qiyam"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.Token.slate800)
                    
                    Text(languageManager.localize("qiyam_tracker_subtitle"))
                        .font(.system(size: 11))
                        .foregroundColor(Color.Token.slate500)
                }
                
                Spacer()
                
                Color.clear.frame(width: 20, height: 20)
            }
            .padding()
            .background(Color.Token.pureWhite)
            .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 2)
            
            ScrollView {
                VStack(spacing: 16) {
                    // Night sky themed stats hero card
                    QiyamHeroCardView(snapshot: snapshot, weekLog: weekLog)
                        .padding(.top, 8)
                    
                    // Tab selection
                    Picker("Qiyam tabs", selection: $selectedTab) {
                        Text(languageManager.localize("qiyam_tab_tracker")).tag(0)
                        Text(languageManager.localize("qiyam_tab_readings")).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Tab content
                    if selectedTab == 0 {
                        // Tracker Tab
                        VStack(alignment: .leading, spacing: 16) {
                            Text(languageManager.localize("qiyam_tracker_desc"))
                                .font(.system(size: 13))
                                .foregroundColor(Color.Token.slate500)
                                .lineSpacing(4)
                                .padding(.horizontal, 4)
                            
                            // Logging switch card
                            Button(action: toggleTonight) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(languageManager.localize("qiyam_prayed_tonight"))
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundColor(Color.Token.deepEmerald)
                                        
                                        Text(languageManager.localize("qiyam_private_tracker"))
                                            .font(.system(size: 12))
                                            .foregroundColor(Color.Token.slate500)
                                    }
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $loggedTonight)
                                        .labelsHidden()
                                        .tint(Color.Token.deepEmerald)
                                        .onChange(of: loggedTonight) { _, newValue in
                                            if newValue != QiyamTrackerStore.shared.isLogged() {
                                                toggleTonight()
                                            }
                                        }
                                }
                                .padding(18)
                                .background(Color.Token.pureWhite)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.Token.softGrey.opacity(0.5), lineWidth: 1)
                                  )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal)
                    } else {
                        // Readings Tab
                        VStack(alignment: .leading, spacing: 16) {
                            Text(languageManager.localize("qiyam_readings_desc"))
                                .font(.system(size: 13))
                                .foregroundColor(Color.Token.slate500)
                                .lineSpacing(4)
                                .padding(.horizontal, 4)
                            
                            ForEach(QiyamGuideCategory.allCases) { category in
                                Text(category.localizedName)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(Color.Token.deepEmerald)
                                    .padding(.top, 8)
                                    .padding(.horizontal, 4)
                                
                                ForEach(readings.filter { $0.category == category }) { reading in
                                    QiyamReadingRow(
                                        reading: reading,
                                        isExpanded: expandedReadings.contains(reading.id),
                                        onTap: {
                                            if expandedReadings.contains(reading.id) {
                                                expandedReadings.remove(reading.id)
                                            } else {
                                                expandedReadings.insert(reading.id)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 30)
            }
            .background(Color.Token.screenBackground)
        }
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            reloadStoreData()
        }
    }
    
    private func reloadStoreData() {
        loggedTonight = QiyamTrackerStore.shared.isLogged()
        snapshot = QiyamTrackerStore.shared.snapshot()
        weekLog = QiyamTrackerStore.shared.last7Days()
    }
    
    private func toggleTonight() {
        let haptic = UIImpactFeedbackGenerator(style: .medium)
        haptic.impactOccurred()
        
        let _ = QiyamTrackerStore.shared.toggleTonight()
        reloadStoreData()
    }
}

// MARK: - Qiyam Hero Card
struct QiyamHeroCardView: View {
    let snapshot: QiyamMonthSnapshot
    let weekLog: [QiyamDayLog]
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.Token.goldDeep)
                
                Spacer().frame(width: 10)
                
                Text(languageManager.localize("qiyam_what_is"))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(nil)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Stat Blocks
            HStack(spacing: 0) {
                Spacer()
                StatBlock(value: "\(snapshot.streak)", label: languageManager.localize("qiyam_streak"))
                Spacer()
                Divider().frame(height: 35).background(Color.white.opacity(0.2))
                Spacer()
                StatBlock(value: "\(snapshot.nightsThisMonth)", label: languageManager.localize("qiyam_this_month"))
                Spacer()
                Divider().frame(height: 35).background(Color.white.opacity(0.2))
                Spacer()
                StatBlock(value: "\(snapshot.nightsLast7Days)", label: languageManager.localize("qiyam_last_7_days"))
                Spacer()
            }
            
            // Week dots
            HStack(spacing: 0) {
                ForEach(weekLog, id: \.dayKey) { day in
                    Spacer()
                    VStack(spacing: 6) {
                        Text(day.weekdayShort)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        
                        Circle()
                            .fill(day.logged ? Color.Token.goldDeep : (day.isToday ? Color.white.opacity(0.35) : Color.white.opacity(0.15)))
                            .frame(width: day.isToday ? 12 : 8, height: day.isToday ? 12 : 8)
                    }
                    Spacer()
                }
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.15, blue: 0.1), Color.Token.indigoDeep, Color.Token.slate900],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
        .padding(.horizontal)
    }
}

struct StatBlock: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.65))
        }
    }
}

// MARK: - Qiyam Reading Row
struct QiyamReadingRow: View {
    let reading: QiyamReading
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Text(reading.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.Token.slate800)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.Token.slate500)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                Divider()
                    .padding(.horizontal, 16)
                
                VStack(alignment: .leading, spacing: 10) {
                    if let arabic = reading.arabic {
                        Text(arabic)
                            .font(.system(size: 20))
                            .foregroundColor(Color.Token.deepEmerald)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .multilineTextAlignment(.trailing)
                            .padding(.top, 4)
                    }
                    
                    if let translit = reading.transliteration {
                        Text(translit)
                            .font(.system(size: 13, weight: .regular))
                            .italic()
                            .foregroundColor(Color.Token.teal)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    Text(reading.body)
                        .font(.system(size: 13))
                        .foregroundColor(Color.Token.slate800)
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
            }
        }
        .background(Color.Token.pureWhite)
        .cornerRadius(14)
        .shadow(color: Color.black.opacity(0.02), radius: 3, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.Token.softGrey.opacity(0.5), lineWidth: 1)
        )
    }
}
