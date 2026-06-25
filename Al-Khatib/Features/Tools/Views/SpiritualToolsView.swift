//
//  SpiritualToolsView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct SpiritualToolsView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Spiritual Tools")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color.Token.deepEmerald)
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                Text("Enhance your daily worship with these local tools and calculators.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color.Token.slate500)
                    .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 16) {
                    NavigationLink(destination: DhikrTasbihView()) {
                        ToolCard(
                            title: "Dhikr & Tasbih",
                            subtitle: "Tasbih counter",
                            iconName: "circle.circle",
                            color: Color.Token.deepEmerald
                        )
                    }
                    
                    NavigationLink(destination: DoaZikirView()) {
                        ToolCard(
                            title: "Doa & Zikir",
                            subtitle: "Collection of prayers",
                            iconName: "book.pages",
                            color: Color.Token.teal
                        )
                    }
                    
                    ToolCardPlaceholder(
                        title: "Qibla Finder",
                        subtitle: "Locate Kaaba direction",
                        iconName: "safari",
                        color: Color.Token.goldDeep
                    )
                    
                    ToolCardPlaceholder(
                        title: "Zakat Calculator",
                        subtitle: "Calculate your zakat",
                        iconName: "percent",
                        color: Color.Token.indigoAccent
                    )
                    
                    ToolCardPlaceholder(
                        title: "Qiyam Guide",
                        subtitle: "Tahajjud guidance",
                        iconName: "moon.stars",
                        color: Color.Token.indigoDeep
                    )
                    
                    ToolCardPlaceholder(
                        title: "Faraidh",
                        subtitle: "Islamic inheritance",
                        iconName: "doc.text",
                        color: Color.Token.slate900
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 30)
        }
        .background(Color.Token.screenBackground)
        .toolbar(.hidden, for: .navigationBar)
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
