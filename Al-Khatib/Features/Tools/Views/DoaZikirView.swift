//
//  DoaZikirView.swift
//  Al-Khatib
//
//  Created by Elmee on 25/06/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

struct SessionDhikrItem: Identifiable, Equatable {
    let id = UUID()
    let bundleTitle: String?
    let arabic: String
    let latin: String
    let translation: String
    let fawaid: String?
    let notes: String?
    let source: String?
    let repeatCount: Int
}

struct DoaZikirView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = DoaZikirViewModel()
    @State private var activeTab = "daftar" // "daftar" or "mulai_dzikir"
    
    @ObservedObject private var languageManager = AppLanguageManager.shared

    private var language: String {
        let raw = languageManager.currentLanguage.rawValue
        return (raw == "id" || raw == "ms") ? "id" : "en"
    }

    private var selectedCategory: DoaCatalogEntry? {
        guard let slug = viewModel.selectedSlug else { return nil }
        return viewModel.catalog.first { $0.slug == slug }
    }

    private var isDhikrCategory: Bool {
        return selectedCategory?.kind == .dhikr
    }

    var body: some View {
        VStack(spacing: 0) {
            // Custom Top Bar
            DoaZikirTopBar(
                inDetail: viewModel.selectedSlug != nil,
                title: viewModel.selectedSlug != nil ? (viewModel.selectedTitle ?? "") : (language == "id" ? "Doa & Zikir" : "Doa & Zikir"),
                onBack: {
                    handleBack()
                }
            )
            
            if viewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .tint(Color.Token.deepEmerald)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.Token.screenBackground)
            } else if viewModel.selectedSlug != nil && isDhikrCategory && activeTab == "mulai_dzikir" {
                ZikirSessionContainer(
                    bundles: viewModel.dhikrBundles,
                    selectedTitle: viewModel.selectedTitle,
                    language: language,
                    onClose: {
                        viewModel.clearSelection()
                        activeTab = "daftar"
                    }
                )
            } else {
                ZStack(alignment: .bottom) {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.selectedSlug == nil {
                                // Categories List
                                ForEach(viewModel.catalog) { entry in
                                    CatalogRow(
                                        title: entry.title,
                                        kindLabel: entry.kind == .dhikr ? (language == "id" ? "Zikir" : "Dhikr") : "Doa",
                                        isDhikr: entry.kind == .dhikr,
                                        onClick: {
                                            Task {
                                                await viewModel.selectCategory(entry)
                                            }
                                        }
                                    )
                                }
                            } else {
                                // Doa Items List
                                if !viewModel.doaItems.isEmpty {
                                    ForEach(viewModel.doaItems) { doa in
                                        PremiumDoaCard(
                                            title: doa.title ?? "",
                                            arabic: doa.arabic ?? "",
                                            latin: doa.latin ?? "",
                                            translation: doa.translation ?? "",
                                            reference: (doa.fawaid != nil && !doa.fawaid!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && doa.fawaid != "-") ? doa.fawaid : nil
                                        )
                                    }
                                }
                                
                                // Dhikr Bundles List
                                ForEach(viewModel.dhikrBundles) { bundle in
                                    let showBundleTitle = viewModel.dhikrBundles.count > 1 || bundle.title != viewModel.selectedTitle
                                    
                                    if showBundleTitle, let title = bundle.title {
                                        HStack {
                                            Text(title)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color.Token.tealDark)
                                                .padding(.leading, 4)
                                                .padding(.top, 8)
                                            Spacer()
                                        }
                                    }
                                    
                                    ForEach(bundle.content ?? [], id: \.self) { item in
                                        PremiumDoaCard(
                                            title: "",
                                            arabic: item.arabic ?? "",
                                            latin: item.latin ?? "",
                                            translation: item.translation ?? "",
                                            reference: (item.source != nil && !item.source!.isEmpty && item.source != "-") ? item.source :
                                                       ((item.fawaid != nil && !item.fawaid!.isEmpty && item.fawaid != "-") ? item.fawaid : nil)
                                        )
                                    }
                                }
                                
                                // Spacer for floating button
                                if isDhikrCategory {
                                    Spacer()
                                        .frame(height: 80)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.Token.screenBackground)
                    
                    // Floating Start Dhikr Button
                    if viewModel.selectedSlug != nil && isDhikrCategory {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            activeTab = "mulai_dzikir"
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text(language == "id" ? "Mulai Zikir" : "Start Dhikr")
                                    .font(.system(size: 15, weight: .bold))
                            }
                            .foregroundColor(Color.Token.pureWhite)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: [Color.Token.deepEmerald, Color.Token.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                        .padding(.bottom, 24)
                        .padding(.trailing, 24)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            Task {
                await viewModel.loadCatalog()
            }
        }
    }

    private func handleBack() {
        if viewModel.selectedSlug != nil {
            if isDhikrCategory && activeTab == "mulai_dzikir" {
                activeTab = "daftar"
            } else {
                viewModel.clearSelection()
            }
        } else {
            dismiss()
        }
    }
}

// Custom Top Bar View
struct DoaZikirTopBar: View {
    let inDetail: Bool
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.Token.deepEmerald)
                    .frame(width: 44, height: 44)
            }
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.Token.deepEmerald)
                .lineLimit(1)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, inDetail ? 10 : 8)
        .background(
            Group {
                if inDetail {
                    LinearGradient(
                        colors: [Color.Token.deepEmerald.opacity(0.12), Color.Token.teal.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .cornerRadius(20, corners: [.bottomLeft, .bottomRight])
                } else {
                    Color.Token.screenBackground
                }
            }
        )
    }
}

// Catalog Row representation
struct CatalogRow: View {
    let title: String
    let kindLabel: String
    let isDhikr: Bool
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 14) {
                // Kind icon container
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isDhikr ? Color.Token.deepEmerald.opacity(0.12) : Color.Token.amberWash)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: isDhikr ? "heart.fill" : "book.closed.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isDhikr ? Color.Token.deepEmerald : Color.Token.goldDeep)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.Token.slate800)
                        .multilineTextAlignment(.leading)
                    
                    Text(kindLabel)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(Color.Token.slate500)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.Token.teal)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.Token.pureWhite, Color.Token.mintWash.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.Token.teal.opacity(0.35), Color.Token.softGrey.opacity(0.55)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }
}

// Premium Doa Card Representation
struct PremiumDoaCard: View {
    let title: String
    let arabic: String
    let latin: String
    let translation: String
    let reference: String?

    var body: some View {
        VStack(spacing: 0) {
            // Top color gradient strip
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.Token.deepEmerald, Color.Token.teal, Color.Token.gold.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 3)
            
            VStack(alignment: .leading, spacing: 14) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.Token.deepEmerald)
                }
                
                if !arabic.isEmpty {
                    HStack {
                        Spacer()
                        Text(arabic)
                            .font(.system(size: 24))
                            .multilineTextAlignment(.trailing)
                            .lineSpacing(10)
                            .foregroundColor(Color.Token.slate900)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 16)
                            .background(Color.Token.deepEmerald.opacity(0.05))
                            .cornerRadius(14)
                    }
                }
                
                if !latin.isEmpty {
                    Text(latin)
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .italic()
                        .foregroundColor(Color.Token.slate500)
                        .lineSpacing(4)
                }
                
                if !translation.isEmpty {
                    Text(translation)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(Color.Token.slate800)
                        .lineSpacing(5)
                }
                
                if let ref = reference {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.Token.teal)
                            .frame(width: 6, height: 6)
                        
                        Text(ref)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.Token.slate500)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.Token.lightGrey.opacity(0.55))
                    .cornerRadius(10)
                }
            }
            .padding(18)
        }
        .background(Color.Token.pureWhite)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.Token.softGrey.opacity(0.75), lineWidth: 1)
        )
    }
}

// Zikir Interactive Session Container
struct ZikirSessionContainer: View {
    let bundles: [DhikrBundle]
    let selectedTitle: String?
    let language: String
    let onClose: () -> Void

    @State private var currentItemIndex = 0
    @State private var currentCount = 0
    @State private var isCompleted = false
    @State private var pulseKey = 0

    private var sessionItems: [SessionDhikrItem] {
        return bundles.flatMap { bundle in
            (bundle.content ?? []).map { item in
                SessionDhikrItem(
                    bundleTitle: bundle.title,
                    arabic: item.arabic ?? "",
                    latin: item.latin ?? "",
                    translation: item.translation ?? "",
                    fawaid: item.fawaid,
                    notes: item.notes,
                    source: item.source,
                    repeatCount: item.repeatCount ?? 1
                )
            }
        }
    }

    private var progressPercent: Double {
        guard !sessionItems.isEmpty else { return 0.0 }
        return Double(currentItemIndex) / Double(sessionItems.count)
    }

    var body: some View {
        if sessionItems.isEmpty {
            VStack {
                Text(language == "id" ? "Zikir kosong" : "Dhikr is empty")
                    .font(.system(size: 16))
                    .foregroundColor(Color.Token.slate500)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.Token.screenBackground)
        } else if isCompleted {
            ZikirCompletionView(
                onReset: {
                    currentItemIndex = 0
                    currentCount = 0
                    isCompleted = false
                },
                onClose: onClose,
                language: language
            )
        } else {
            let activeItem = sessionItems[currentItemIndex]
            
            VStack(spacing: 0) {
                // Progress view
                VStack(spacing: 8) {
                    HStack {
                        Text(language == "id" ? "Dzikir \(currentItemIndex + 1) dari \(sessionItems.count)" : "Dhikr \(currentItemIndex + 1) of \(sessionItems.count)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.Token.deepEmerald)
                        
                        Spacer()
                        
                        Text("\(Int(progressPercent * 100))%")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(Color.Token.slate500)
                    }
                    
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color(hex: "#E2E8F0"))
                            
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.Token.deepEmerald)
                                .frame(width: geo.size.width * CGFloat(progressPercent))
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.Token.pureWhite)
                
                Divider()
                
                ZStack(alignment: .bottomTrailing) {
                    // Scrollable Zikir Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            if let bundleTitle = activeItem.bundleTitle, bundleTitle != selectedTitle {
                                Text(bundleTitle)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(Color.Token.teal)
                                    .padding(.bottom, -8)
                            }
                            
                            if !activeItem.arabic.isEmpty {
                                Text(activeItem.arabic)
                                    .font(.system(size: 26))
                                    .multilineTextAlignment(.trailing)
                                    .lineSpacing(10)
                                    .foregroundColor(Color.Token.slate900)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                                    .padding(16)
                                    .background(Color.Token.deepEmerald.opacity(0.05))
                                    .cornerRadius(16)
                            }
                            
                            if !activeItem.latin.isEmpty {
                                Text(activeItem.latin)
                                    .font(.system(size: 14, weight: .medium, design: .serif))
                                    .italic()
                                    .foregroundColor(Color.Token.slate500)
                                    .lineSpacing(4)
                            }
                            
                            if !activeItem.translation.isEmpty {
                                Text(activeItem.translation)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(Color.Token.slate800)
                                    .lineSpacing(5)
                            }
                            
                            let referenceSource = (activeItem.source != nil && !activeItem.source!.isEmpty && activeItem.source != "-") ? activeItem.source :
                                                  ((activeItem.fawaid != nil && !activeItem.fawaid!.isEmpty && activeItem.fawaid != "-") ? activeItem.fawaid : nil)
                            
                            if let ref = referenceSource {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color.Token.goldDeep)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(ref)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(Color.Token.slate800)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(Color(hex: "#F1F5F9"))
                                .cornerRadius(12)
                            }
                            
                            // Bottom padding so content is not hidden behind the floating counter button
                            Spacer()
                                .frame(height: 120)
                        }
                        .padding(20)
                        .background(Color.Token.pureWhite)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.Token.teal.opacity(0.25), Color.Token.gold.opacity(0.2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                        .padding(16)
                        // Transition animation for changing cards
                        .id(currentItemIndex)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.Token.screenBackground)
                    
                    // Floating Interactive Tasbih Counter
                    Button(action: {
                        incrementCount(activeItem: activeItem)
                    }) {
                        PremiumTasbihCounter(
                            count: currentCount,
                            target: activeItem.repeatCount,
                            pulseKey: pulseKey,
                            subtitle: "\(activeItem.repeatCount)x",
                            counterSize: 96
                        )
                    }
                    .padding(.bottom, 64)
                    .padding(.trailing, 24)
                }
                
                Divider()
                
                // Bottom control panel
                HStack {
                    // Previous Button
                    Button(action: {
                        if currentItemIndex > 0 {
                            withAnimation(.easeInOut) {
                                currentItemIndex -= 1
                                currentCount = 0
                            }
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(currentItemIndex > 0 ? Color.Token.deepEmerald : Color.Token.slate500.opacity(0.3))
                            .frame(width: 44, height: 44)
                    }
                    .disabled(currentItemIndex == 0)
                    
                    Spacer()
                    
                    // Reset count button
                    Button(action: {
                        currentCount = 0
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.Token.slate500)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    // Skip Button
                    Button(action: {
                        skipItem()
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color.Token.deepEmerald)
                            .frame(width: 44, height: 44)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(Color.Token.pureWhite)
            }
        }
    }

    private func incrementCount(activeItem: SessionDhikrItem) {
        if isCompleted || currentCount >= activeItem.repeatCount { return }
        
        let nextCount = currentCount + 1
        currentCount = nextCount
        pulseKey += 1
        
        // Tap haptic
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        if nextCount == activeItem.repeatCount {
            // Target confirmation haptic
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            // Wait 320ms and proceed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
                if currentItemIndex < sessionItems.count - 1 {
                    withAnimation(.easeInOut) {
                        currentItemIndex += 1
                        currentCount = 0
                    }
                } else {
                    isCompleted = true
                }
            }
        }
    }

    private func skipItem() {
        if currentItemIndex < sessionItems.count - 1 {
            withAnimation(.easeInOut) {
                currentItemIndex += 1
                currentCount = 0
            }
        } else {
            isCompleted = true
        }
    }
}

// Zikir Completion view screen
struct ZikirCompletionView: View {
    let onReset: () -> Void
    let onClose: () -> Void
    let language: String

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                // Heart completion badge
                ZStack {
                    Circle()
                        .fill(Color.Token.deepEmerald.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Color.Token.deepEmerald)
                }
                
                Text("Alhamdulillah")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(Color.Token.deepEmerald)
                
                Text(language == "id" ? "Anda telah menyelesaikan seluruh rangkaian zikir dengan baik. Semoga Allah menerima amal ibadah Anda." : "You have successfully completed the entire dhikr series. May Allah accept your worship.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color.Token.slate800)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .padding(.horizontal, 24)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                // Repeat Button
                Button(action: onReset) {
                    Text(language == "id" ? "Ulangi Zikir" : "Repeat Dhikr")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.Token.pureWhite)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.Token.deepEmerald)
                        .cornerRadius(16)
                }
                
                // Back to Menu Button
                Button(action: onClose) {
                    Text(language == "id" ? "Kembali ke Menu" : "Back to Menu")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.Token.deepEmerald)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.Token.deepEmerald, lineWidth: 1)
                        )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.Token.screenBackground)
    }
}

// Helper extension to support specific corner rounding in SwiftUI
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    let radius: CGFloat
    let corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

#Preview {
    DoaZikirView()
}
