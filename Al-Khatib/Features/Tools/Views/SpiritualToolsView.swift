//
//  SpiritualToolsView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct SpiritualToolsView: View {
    @ObservedObject private var languageManager = AppLanguageManager.shared
    
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(languageManager.localize("tools_desc"))
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.Token.slate500)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink(destination: DhikrTasbihView().toolbar(.hidden, for: .tabBar)) {
                        ToolCard(
                             title: languageManager.localize("tool_tasbih"),
                             subtitle: languageManager.localize("tool_tasbih_sub"),
                             iconName: "circle.circle",
                             color: Color.Token.deepEmerald
                        )
                    }
                    
                    NavigationLink(destination: DoaZikirView().toolbar(.hidden, for: .tabBar)) {
                        ToolCard(
                             title: languageManager.localize("tool_doa_zikir"),
                             subtitle: languageManager.localize("tool_doa_zikir_sub"),
                             iconName: "book.pages",
                             color: Color.Token.teal
                        )
                    }
                    
                    NavigationLink(destination: QiblaFinderView().toolbar(.hidden, for: .tabBar)) {
                        ToolCard(
                             title: languageManager.localize("tool_qibla"),
                             subtitle: languageManager.localize("tool_qibla_sub"),
                             iconName: "safari",
                             color: Color.Token.goldDeep
                        )
                    }
                    
                    NavigationLink(destination: ZakatCalculatorView().toolbar(.hidden, for: .tabBar)) {
                        ToolCard(
                             title: languageManager.localize("tool_zakat"),
                             subtitle: languageManager.localize("tool_zakat_sub"),
                             iconName: "percent",
                             color: Color.Token.indigoAccent
                        )
                    }
                    
                    NavigationLink(destination: QiyamTrackerView().toolbar(.hidden, for: .tabBar)) {
                        ToolCard(
                             title: languageManager.localize("tool_qiyam"),
                             subtitle: languageManager.localize("tool_qiyam_sub"),
                             iconName: "moon.stars",
                             color: Color.Token.indigoDeep
                        )
                    }
                    
                    NavigationLink(destination: FaraidhCalculatorView().toolbar(.hidden, for: .tabBar)) {
                        ToolCard(
                             title: languageManager.localize("tool_faraidh"),
                             subtitle: languageManager.localize("tool_faraidh_sub"),
                             iconName: "doc.text",
                             color: Color.Token.slate900
                        )
                    }

                    NavigationLink(destination: ManzilView().toolbar(.hidden, for: .tabBar)) {
                        ToolCard(
                             title: languageManager.localize("tool_manzil"),
                             subtitle: languageManager.localize("tool_manzil_sub"),
                             iconName: "shield.checkerboard",
                             color: Color.Token.deepEmerald
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .background(Color.Token.screenBackground)
        .navigationTitle(languageManager.localize("tools_title"))
        .navigationBarTitleDisplayMode(.large)
    }
}

struct ToolCard: View {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: iconName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.Token.slate800)
                    .multilineTextAlignment(.leading)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(Color.Token.slate500)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.Token.pureWhite)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

struct ToolCardPlaceholder: View {
    let title: String
    let subtitle: String
    let iconName: String
    let color: Color
    
    @State private var showAlert = false

    var body: some View {
        Button(action: {
            showAlert = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color.opacity(0.6))
                    .frame(width: 48, height: 48)
                    .background(color.opacity(0.05))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(Color.Token.slate800.opacity(0.7))
                        .multilineTextAlignment(.leading)
                    
                    Text(subtitle)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.Token.slate500.opacity(0.7))
                        .multilineTextAlignment(.leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.Token.pureWhite)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.02), radius: 6, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.Token.softGrey.opacity(0.5), lineWidth: 1)
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("\(title) Tool"),
                message: Text("This tool will be available in a future update. For now, check out the Dhikr & Tasbih and Doa & Zikir features!"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
