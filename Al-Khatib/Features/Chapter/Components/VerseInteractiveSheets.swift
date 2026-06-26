//
//  VerseInteractiveSheets.swift
//  Al-Khatib
//
//  Created by Elmee on 26/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct VerseAISheet: View {
    let surahName: String
    let verseNumber: Int
    let verseText: String
    let translationText: String
    
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
            // Simulate AI Generating
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            reflectionText = generateReflection()
            withAnimation(.easeOut(duration: 0.4)) {
                isLoading = false
            }
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
                        Text(AppLanguageManager.shared.currentLanguage == .english ? "AI Spiritual Reflection" : "Tafsir Renungan AI")
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
                    Text(AppLanguageManager.shared.currentLanguage == .english ? "Reflective Insight" : "Tinjauan Renungan")
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
                
                // Action Buttons
                Button {
                    // Action: Post or share
                    dismiss()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "paperplane.fill")
                        Text(AppLanguageManager.shared.currentLanguage == .english ? "Share to Feed" : "Bagikan ke Refleksi")
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
    
    private func generateReflection() -> String {
        // Build a dynamic reflection based on the surah name
        let lang = AppLanguageManager.shared.currentLanguage
        if lang == .english {
            return "This verse from \(surahName) reminds us of the infinite wisdom of Allah. The phrase reminds us to align our hearts with the remembrance of the Divine, especially when facing life's daily pressures. By seeking refuge in prayer and understanding the deep teachings of this Ayah, we cultivate patience, gratitude, and a resilient spiritual posture. Let this reflection guide your actions today, bringing clarity to your thoughts and peace to your heart."
        } else {
            return "Ayat ini dari Surah \(surahName) mengingatkan kita akan kebijaksanaan Allah yang tidak terbatas. Pesan mendalam di dalamnya mengajak kita untuk senantiasa menyelaraskan hati dengan mengingat Sang Pencipta, terutama saat menghadapi tekanan hidup sehari-hari. Dengan merenungi makna ayat ini, kita diajarkan untuk memupuk kesabaran, keikhlasan, dan keteguhan iman. Jadikan renungan ini sebagai panduan langkah Anda hari ini, membawa ketenangan pada pikiran dan kedamaian dalam jiwa."
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
