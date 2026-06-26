//
//  VerseInteractiveSheets.swift
//  Al-Khatib
//
//  Created by Elmee on 26/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct VerseReflectionSheet: View {
    let surahName: String
    let verseNumber: Int
    let verseText: String
    let translationText: String
    let verseKey: String
    let contentRepository: QuranContentRepository?
    
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var animationPulse = false
    @State private var reflectionText = ""
    
    var body: some View {
        ZStack {
            // Dark elegant background
            Color.Token.forestDeeper
                .ignoresSafeArea()
            
            // Soft ambient glow
            RadialGradient(
                colors: [Color.Token.deepEmerald.opacity(0.4), Color.clear],
                center: .top,
                startRadius: 10,
                endRadius: 300
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 20)
                
                if isLoading {
                    loadingView
                } else {
                    contentView
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .task {
            await loadReflection()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ZStack {
                Circle()
                    .stroke(Color.Token.gold.opacity(0.15), lineWidth: 4)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: 0.6)
                    .stroke(
                        LinearGradient(
                            colors: [Color.Token.goldBright, Color.Token.deepEmerald],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(animationPulse ? 360 : 0))
                    .onAppear {
                        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                            animationPulse = true
                        }
                    }
                
                Image(systemName: "sparkles")
                    .font(.system(size: 28))
                    .foregroundColor(Color.Token.goldBright)
                    .scaleEffect(animationPulse ? 1.15 : 0.9)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animationPulse)
            }
            
            VStack(spacing: 8) {
                Text(AppLanguageManager.shared.currentLanguage == .english ? "Analyzing Verse..." : "Menganalisis Ayat...")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.white)
                
                Text(AppLanguageManager.shared.currentLanguage == .english ? "Generating AI Spiritual Reflection" : "Membuat Renungan Spiritual AI")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
        }
    }
    
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title Block
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(Color.Token.goldBright)
                        
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(surahName) • \(AppLanguageManager.shared.currentLanguage == .english ? "Ayah" : "Ayat") \(verseNumber)")
                            .font(.headline.weight(.bold))
                            .foregroundColor(.white)
                        Text(AppLanguageManager.shared.localize("ai_reflection"))
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.Token.goldBright)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Original Verse card
                VStack(spacing: 12) {
                    Text(verseText)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                    
                    Text(translationText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.04))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.Token.gold.opacity(0.25), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                
                // AI Reflection Result
                VStack(alignment: .leading, spacing: 12) {
                    Text(AppLanguageManager.shared.currentLanguage == .english ? "AI Spiritual Reflection" : "Renungan Spiritual AI")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(Color.Token.goldBright)
                        .textCase(.uppercase)
                        .tracking(1.0)
                    
                    Text(reflectionText)
                        .font(.system(size: 15, weight: .regular, design: .serif))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(6)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.Token.readerForest.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
                
                // Share to WhatsApp/Other Apps
                ShareLink(
                    item: shareText,
                    subject: Text(AppLanguageManager.shared.currentLanguage == .english ? "Al-Khatib AI Reflection" : "Renungan AI Al-Khatib"),
                    message: Text(shareText)
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text(AppLanguageManager.shared.currentLanguage == .english ? "Share Reflection" : "Bagikan Renungan")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(
                            colors: [Color.Token.deepEmerald, Color.Token.tealDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
                }
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
    }
    
    private var shareText: String {
        let lang = AppLanguageManager.shared.currentLanguage
        let appName = "Al-Khatib"
        let title = lang == .english ? "✨ AI Spiritual Reflection - \(appName) ✨" : "✨ Renungan Spiritual AI - \(appName) ✨"
        let header = "\(surahName) • \(lang == .english ? "Ayah" : "Ayat") \(verseNumber)"
        
        return """
        \(title)
        \(header)
        
        📖 "\(translationText)"
        
        \(reflectionText)
        
        \(lang == .english ? "Shared via Al-Khatib App" : "Dibagikan via Aplikasi Al-Khatib")
        """
    }
    
    private func loadReflection() async {
        var tafsirText = ""
        if let repo = contentRepository {
            if let response = try? await repo.getTafsirByAyah(resourceId: "169", ayahKey: verseKey) {
                tafsirText = response.tafsir?.textStrippingHTML?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            }
        }
        
        let client = AIClient()
        let lang = AppLanguageManager.shared.currentLanguage
        
        let systemPrompt: String
        let userPrompt: String
        
        if lang == .english {
            systemPrompt = """
            You are a wise, deeply reflective, and gentle Islamic spiritual AI assistant. Your task is to write a soulful spiritual reflection (tadabbur) based on the Quranic verse and tafsir provided.
            Write your reflection in a structured format with three distinct sections (use bold headers, no special markdown formatting):
            1. **Introduction** (A gentle, inspiring context or opening for the verse)
            2. **Core Wisdom** (The deep spiritual lessons and wisdom of the verse)
            3. **Practical Application** (Concrete steps or self-reflection for daily life)
            
            Provide a comprehensive, detailed, and deep reflection (total length between 150-250 words). Ensure the tone is beautiful, calming, and aligned with standard Islamic creed. Do not invent hadith.
            """
            userPrompt = """
            Write a spiritual reflection for the following verse:
            Surah: \(surahName)
            Verse: \(verseNumber)
            Arabic Text: \(verseText)
            Translation: \(translationText)
            Tafsir Context: \(tafsirText.isEmpty ? "N/A" : tafsirText)
            
            Write the complete reflection in English, structured with Introduction, Core Wisdom, and Practical Application.
            """
        } else {
            systemPrompt = """
            Anda adalah asisten AI spiritual Islam yang bijaksana, mendalam, dan santun. Tugas Anda adalah memberikan renungan spiritual (tadabbur) yang menyentuh hati berdasarkan ayat Al-Quran dan tafsir yang disediakan.
            Tulis penjelasan Anda secara terstruktur dengan tiga bagian berikut (gunakan subjudul tebal, tanpa simbol markdown aneh):
            1. **Pendahuluan** (Konteks atau pengantar ayat yang lembut dan inspiratif)
            2. **Intisari** (Makna mendalam dan hikmah spiritual dari ayat tersebut)
            3. **Aplikasi Praktis** (Langkah konkret atau introspeksi diri sehari-hari yang dapat diamalkan oleh pembaca)
            
            Berikan penjelasan yang lengkap, detail, dan mendalam (panjang total sekitar 150-250 kata). Pastikan bahasa yang digunakan sangat indah, menyejukkan, dan sesuai dengan akidah Ahlus Sunnah wal Jama'ah. Jangan mengarang hadis palsu.
            """
            userPrompt = """
            Berikan renungan spiritual untuk ayat berikut:
            Surah: \(surahName)
            Ayat: \(verseNumber)
            Teks Arab: \(verseText)
            Terjemahan: \(translationText)
            Konteks Tafsir: \(tafsirText.isEmpty ? "N/A" : tafsirText)
            
            Tulis renungan lengkap dalam bahasa Indonesia secara terstruktur (Pendahuluan, Intisari, Aplikasi Praktis).
            """
        }
        
        let result = await client.complete(system: systemPrompt, user: userPrompt, temperature: 0.35)
        
        if let result, result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false {
            self.reflectionText = result
        } else {
            self.reflectionText = generateFallbackReflection()
        }
        
        withAnimation(.easeOut(duration: 0.4)) {
            isLoading = false
        }
    }
    
    private func generateFallbackReflection() -> String {
        let lang = AppLanguageManager.shared.currentLanguage
        if lang == .english {
            return """
            **Introduction**
            This beautiful verse from \(surahName) opens our hearts to the deep mercy and wisdom of the Almighty. It serves as a gentle reminder of our journey back to our Creator.
            
            **Core Wisdom**
            The verse emphasizes steadfast faith and patience. When we align our daily actions with the guidance of this Ayah, we cultivate a stronger connection to the Divine, anchoring our souls in tranquility.
            
            **Practical Application**
            Let us take a moment today to reflect on our words and actions. Strive to be more patient with those around us, and seek strength through prayer and remembrance.
            """
        } else {
            return """
            **Pendahuluan**
            Ayat yang indah dari Surah \(surahName) ini membuka hati kita terhadap rahmat dan kebijaksanaan tak terbatas dari Allah SWT. Ini adalah pengingat lembut tentang perjalanan pulang jiwa kita.
            
            **Intisari**
            Makna mendalam dari ayat ini menekankan pentingnya keikhlasan dan keteguhan iman. Dengan menyelaraskan langkah kita sesuai petunjuk-Nya, kita menemukan kedamaian sejati dalam mengingat-Nya.
            
            **Aplikasi Praktis**
            Mari luangkan waktu hari ini untuk mengoreksi diri kita. Cobalah bersikap lebih sabar terhadap sesama, dan perkuat hati kita dengan senantiasa bersyukur atas segala nikmat-Nya.
            """
        }
    }
}

struct VerseNoteSheet: View {
    let surahName: String
    let verseNumber: Int
    let verseKey: String
    let onSave: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var noteText = ""
    
    init(surahName: String, verseNumber: Int, verseKey: String, onSave: @escaping () -> Void) {
        self.surahName = surahName
        self.verseNumber = verseNumber
        self.verseKey = verseKey
        self.onSave = onSave
        
        // Retrieve note from UserDefaults if exists
        if let existing = UserDefaults.standard.string(forKey: "verse_note_\(verseKey)") {
            _noteText = State(initialValue: existing)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.Token.forestDeeper
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("\(surahName) • \(AppLanguageManager.shared.currentLanguage == .english ? "Ayah" : "Ayat") \(verseNumber)")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text(AppLanguageManager.shared.currentLanguage == .english ? "Write your personal reflection or note below" : "Tulis catatan atau renungan pribadi Anda")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    TextEditor(text: $noteText)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden) // Required to make background color work on iOS 16+
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .frame(maxHeight: .infinity)
                    
                    Button {
                        // Save to UserDefaults
                        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmed.isEmpty {
                            UserDefaults.standard.removeObject(forKey: "verse_note_\(verseKey)")
                        } else {
                            UserDefaults.standard.set(trimmed, forKey: "verse_note_\(verseKey)")
                        }
                        onSave()
                        dismiss()
                    } label: {
                        Text(AppLanguageManager.shared.currentLanguage == .english ? "Save Note" : "Simpan Catatan")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.Token.deepEmerald)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle(AppLanguageManager.shared.currentLanguage == .english ? "Personal Notes" : "Catatan Pribadi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(AppLanguageManager.shared.currentLanguage == .english ? "Cancel" : "Batal") { dismiss() }
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
