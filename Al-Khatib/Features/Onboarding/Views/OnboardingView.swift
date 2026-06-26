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

class OnboardingLocationDelegate: NSObject, CLLocationManagerDelegate {
    let onStatusChanged: (CLAuthorizationStatus) -> Void
    
    init(onStatusChanged: @escaping (CLAuthorizationStatus) -> Void) {
        self.onStatusChanged = onStatusChanged
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        onStatusChanged(manager.authorizationStatus)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        onStatusChanged(status)
    }
}

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    @State private var step: Int = 1
    @State private var locationManager: CLLocationManager?
    @State private var locationDelegate: OnboardingLocationDelegate?
    @State private var isRequestingLocation = false
    
    var body: some View {
        ZStack {
            // Light background matching the app's clean light theme
            Color.Token.screenBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Progress indicator
                progressBar
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                
                Spacer()
                
                // Screen content
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
                
                // Bottom actions container
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
                .foregroundColor(Color.Token.slate500)
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.Token.lightGrey)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.Token.deepEmerald)
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
                .frame(height: 160)
                .foregroundColor(Color.Token.deepEmerald)
            
            VStack(spacing: 12) {
                Text(languageManager.localize("onboarding_welcome_title"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color.Token.slate900)
                    .multilineTextAlignment(.center)
                
                Text(languageManager.localize("onboarding_welcome_subtitle"))
                    .font(.body)
                    .foregroundColor(Color.Token.slate500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(4)
            }
            
            VStack(spacing: 12) {
                Text(languageManager.localize("onboarding_select_language"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.Token.deepEmerald)
                
                HStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            withAnimation {
                                languageManager.currentLanguage = lang
                            }
                        } label: {
                            Text(lang.displayName)
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(languageManager.currentLanguage == lang ? Color.Token.deepEmerald : Color.Token.lightGrey)
                                )
                                .foregroundColor(languageManager.currentLanguage == lang ? .white : Color.Token.slate800)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.Token.softGrey, lineWidth: languageManager.currentLanguage == lang ? 0 : 0.5)
                                )
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
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.mintWash, Color.Token.sageTint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(Color.Token.deepEmerald)
            }
            
            VStack(spacing: 12) {
                Text(languageManager.localize("onboarding_location_title"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color.Token.slate900)
                    .multilineTextAlignment(.center)
                
                Text(languageManager.localize("onboarding_location_subtitle"))
                    .font(.body)
                    .foregroundColor(Color.Token.slate500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var notificationsStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.mintWash, Color.Token.sageTint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(Color.Token.deepEmerald)
            }
            
            VStack(spacing: 12) {
                Text(languageManager.localize("onboarding_notifications_title"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color.Token.slate900)
                    .multilineTextAlignment(.center)
                
                Text(languageManager.localize("onboarding_notifications_subtitle"))
                    .font(.body)
                    .foregroundColor(Color.Token.slate500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var widgetStep: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.Token.mintWash, Color.Token.sageTint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: "square.text.square.fill")
                    .font(.system(size: 56, weight: .semibold))
                    .foregroundColor(Color.Token.deepEmerald)
            }
            
            VStack(spacing: 12) {
                Text(languageManager.localize("onboarding_widgets_title"))
                    .font(.title2.weight(.bold))
                    .foregroundColor(Color.Token.slate900)
                    .multilineTextAlignment(.center)
                
                Text(languageManager.localize("onboarding_widgets_subtitle"))
                    .font(.body)
                    .foregroundColor(Color.Token.slate500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .lineSpacing(4)
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
                    .background(
                        LinearGradient(
                            colors: [Color.Token.deepEmerald, Color.Token.tealDark],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .disabled(isRequestingLocation)
            .opacity(isRequestingLocation ? 0.6 : 1.0)
            
            if step > 1 {
                Button {
                    handleSecondaryAction()
                } label: {
                    Text(secondaryButtonTitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.Token.slate500)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .disabled(isRequestingLocation)
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
            withAnimation {
                step = 2
            }
        case 2:
            let status = CLLocationManager().authorizationStatus
            if status == .notDetermined {
                isRequestingLocation = true
                requestLocationPermission()
            } else {
                withAnimation {
                    step = 3
                }
            }
        case 3:
            requestNotificationPermission {
                DispatchQueue.main.async {
                    withAnimation {
                        step = 4
                    }
                }
            }
        default:
            hasCompletedOnboarding = true
        }
    }
    
    private func handleSecondaryAction() {
        if step < 4 {
            withAnimation {
                step += 1
            }
        }
    }
    
    private func requestLocationPermission() {
        let manager = CLLocationManager()
        let delegate = OnboardingLocationDelegate { status in
            if status != .notDetermined {
                DispatchQueue.main.async {
                    self.isRequestingLocation = false
                    withAnimation {
                        self.step = 3
                    }
                }
            }
        }
        manager.delegate = delegate
        self.locationDelegate = delegate
        self.locationManager = manager
        manager.requestWhenInUseAuthorization()
    }
    
    private func requestNotificationPermission(completion: @escaping () -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            completion()
        }
    }
}
