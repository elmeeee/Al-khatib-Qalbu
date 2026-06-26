//
//  AdhanVoiceSelectionSheet.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import AVFoundation

struct AdhanVoiceOption: Identifiable, Sendable {
    let id: String
    let displayName: String
    let fileName: String
}

struct AdhanVoiceSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    @State private var selectedSoundName = UserDefaults.standard.string(forKey: "selected_adhan_sound") ?? "default"
    @State private var audioPlayer: AVAudioPlayer? = nil
    @State private var playingOptionId: String? = nil
    
    private var options: [AdhanVoiceOption] {
        [
            AdhanVoiceOption(id: "default", displayName: languageManager.localize("system_default_notification"), fileName: "default"),
            AdhanVoiceOption(id: "ust_daeng", displayName: languageManager.localize("adhan_ust_daeng"), fileName: "adhan_ust_daeng_syawal_indonesia"),
            AdhanVoiceOption(id: "sadid_ahmad", displayName: languageManager.localize("adhan_sadid_ahmad"), fileName: "adhan_ustaz_sadid_ahmad_dahri_singapore"),
            AdhanVoiceOption(id: "omar_hisham", displayName: languageManager.localize("adhan_omar_hisham"), fileName: "adhan_omar_hisham_al_arabi"),
            AdhanVoiceOption(id: "abdul_karim", displayName: languageManager.localize("adhan_abdul_karim"), fileName: "adhan_sheikh_abdul_karim_malaysia"),
            AdhanVoiceOption(id: "fajr_mishary", displayName: languageManager.localize("adhan_fajr_mishary"), fileName: "adhan_fajr_mishary_alafasy")
        ]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Sheet Header
            HStack {
                Text(languageManager.localize("select_adhan_voice"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.Token.slate800)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Text(languageManager.localize("done"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                }
            }
            .padding()
            .background(Color.Token.pureWhite)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    Text(languageManager.localize("adhan_voice_desc"))
                        .font(.system(size: 13))
                        .foregroundColor(Color.Token.slate500)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 12)
                    
                    VStack(spacing: 0) {
                        ForEach(options) { option in
                            HStack {
                                // Selection Checkmark & Name
                                Button(action: {
                                    selectedSoundName = option.fileName
                                    UserDefaults.standard.set(option.fileName, forKey: "selected_adhan_sound")
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: selectedSoundName == option.fileName ? "checkmark.circle.fill" : "circle")
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedSoundName == option.fileName ? Color.Token.deepEmerald : Color.Token.slate400)
                                        
                                        Text(option.displayName)
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(Color.Token.slate800)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Preview Play Button
                                if option.id != "default" {
                                    Button(action: { togglePreview(option) }) {
                                        Image(systemName: playingOptionId == option.id ? "stop.fill" : "play.fill")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 28, height: 28)
                                            .background(playingOptionId == option.id ? .red : Color.Token.deepEmerald)
                                            .clipShape(Circle())
                                    }
                                    .accessibilityLabel(playingOptionId == option.id ? "Stop preview" : "Play preview")
                                }
                            }
                            .padding(.vertical, 14)
                            .padding(.horizontal, 16)
                            
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                    .background(Color.Token.pureWhite)
                    .cornerRadius(12)
                    .padding()
                }
            }
            .background(Color.Token.screenBackground)
        }
        .onDisappear {
            stopPreview()
        }
    }
    
    private func togglePreview(_ option: AdhanVoiceOption) {
        if playingOptionId == option.id {
            stopPreview()
        } else {
            playPreview(option)
        }
    }
    
    private func playPreview(_ option: AdhanVoiceOption) {
        stopPreview()
        
        guard let url = Bundle.main.url(forResource: option.fileName, withExtension: "mp3") ??
                        Bundle.main.url(forResource: option.fileName, withExtension: "mp3", subdirectory: "adhan") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
            playingOptionId = option.id
        } catch {
            print("Failed to play Adhan preview: \(error)")
        }
    }
    
    private func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        playingOptionId = nil
    }
}
