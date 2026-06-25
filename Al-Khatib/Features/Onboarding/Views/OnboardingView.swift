//
//  OnboardingView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import CoreLocation
import UserNotifications

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    @State private var step: Int = 1
    @State private var locationManager: CLLocationManager?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color.Token.deepEmerald,
                    Color.Token.tealDark
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                
                Spacer()
                
                Group {
                    switch step {
                    case 1:
                        welcomeStep
                    case 2:
                        locationStep
                    case 3:
                        notificationsStep
                    default:
                        widgetStep
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                
                Spacer()
                
                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 36)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: step)
    }
    
    private var progressBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            let stepText = String(format: languageManager.localize("onboarding_step"), step)
            Text(stepText)
                .font(.caption.weight(.bold))
                .foregroundColor(.white.opacity(0.8))
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.white.opacity(0.2))
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.Token.gold)
                        .frame(width: geo.size.width * CGFloat(step) / 4.0, height: 6)
                        .animation(.spring(), value: step)
                }
            }
            .frame(height: 6)
        }
    }
    
    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Image("OnboardingIllustration")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .foregroundColor(Color.Token.gold)
            
            VStack(spacing: 8) {
                Text(languageManager.localize("onboarding_welcome_title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(languageManager.localize("onboarding_welcome_subtitle"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
            
            VStack(spacing: 12) {
                Text(languageManager.localize("onboarding_select_language"))
                    .font(.subheadline.bold())
                    .foregroundColor(Color.Token.gold)
                
                HStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            languageManager.currentLanguage = lang
                        } label: {
                            Text(lang.displayName)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(languageManager.currentLanguage == lang ? Color.Token.gold : .white.opacity(0.15))
                                )
                                .foregroundColor(languageManager.currentLanguage == lang ? Color.Token.deepEmerald : .white)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 24)
    }
    
    private var locationStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color.Token.gold)
            
            VStack(spacing: 8) {
                Text(languageManager.localize("onboarding_location_title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(languageManager.localize("onboarding_location_subtitle"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var notificationsStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "bell.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Color.Token.gold)
            
            VStack(spacing: 8) {
                Text(languageManager.localize("onboarding_notifications_title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(languageManager.localize("onboarding_notifications_subtitle"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var widgetStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "square.text.square.fill")
                .font(.system(size: 80))
                .foregroundColor(Color.Token.gold)
            
            VStack(spacing: 8) {
                Text(languageManager.localize("onboarding_widgets_title"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(languageManager.localize("onboarding_widgets_subtitle"))
                    .font(.body)
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var bottomControls: some View {
        VStack(spacing: 12) {
            Button {
                handlePrimaryAction()
            } label: {
                Text(primaryButtonTitle)
                    .frame(maxWidth: .infinity)
                    .font(.headline)
                    .padding(.vertical, 14)
                    .background(Color.Token.gold)
                    .foregroundColor(Color.Token.deepEmerald)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            if step > 1 {
                Button {
                    handleSecondaryAction()
                } label: {
                    Text(secondaryButtonTitle)
                        .font(.subheadline.bold())
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var primaryButtonTitle: String {
        switch step {
        case 1: return languageManager.localize("onboarding_continue")
        case 2: return languageManager.localize("onboarding_use_gps")
        case 3: return languageManager.localize("onboarding_enable_notifications")
        default: return languageManager.localize("onboarding_get_started")
        }
    }
    
    private var secondaryButtonTitle: String {
        switch step {
        case 2: return languageManager.localize("onboarding_location_skip")
        case 3: return languageManager.localize("onboarding_notifications_skip")
        default: return ""
        }
    }
    
    private func handlePrimaryAction() {
        switch step {
        case 1:
            step = 2
        case 2:
            requestLocationPermission()
            step = 3
        case 3:
            requestNotificationPermission()
            step = 4
        default:
            hasCompletedOnboarding = true
        }
    }
    
    private func handleSecondaryAction() {
        if step < 4 {
            step += 1
        }
    }
    
    private func requestLocationPermission() {
        let manager = CLLocationManager()
        locationManager = manager
        manager.requestWhenInUseAuthorization()
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
}
