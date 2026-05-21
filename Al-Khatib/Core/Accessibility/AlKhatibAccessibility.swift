//
//  AlKhatibAccessibility.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI

enum AlKhatibAccessibility {
    enum Tab {
        static let today = "Today"
        static let todayHint = "Prayer times, verse of the day, and daily actions"
        static let reflect = "Reflect"
        static let reflectHint = "Community reflections on the Quran"
        static let quran = "Quran"
        static let quranHint = "Browse surahs and read with audio"
    }

    enum Today {
        static let account = "Account and settings"
        static let accountHint = "Profile, translation, notifications, and sign in"
        static let verseOfTheDay = "Verse of the day"
        static let location = "Prayer location"
    }

    enum VerseActions {
        static func audio(hint reciter: String) -> String {
            reciter.isEmpty
                ? "Play recitation of this ayah"
                : "Play recitation by \(reciter)"
        }
        static let share = "Share this ayah"
        static let shareHint = "Share Arabic text, translation, or reflection"
        static let reflect = "Post a reflection"
        static let reflectHint = "Share what this ayah means to you on Reflect"
        static let tafsir = "Read tafsir"
        static let tafsirHint = "Open commentary for this ayah"
    }

    enum Reader {
        static let back = "Back to surah list"
        static let settings = "Reading settings"
        static let settingsHint = "Font size, translation, and reciter"
        static let hadith = "Hadith for this ayah"
        static let tafsir = "Tafsir for this ayah"
        static let playAyah = "Play or pause ayah audio"
    }

    enum Profile {
        static func toggle(_ title: String, subtitle: String, isOn: Bool) -> String {
            "\(title), \(isOn ? "on" : "off"). \(subtitle)"
        }
        static let fontSize = "Reading font size"
        static let prayerCalculation = "Prayer time calculation method"
        static let translator = "Quran translation"
        static let signIn = "Sign in to Quran Reflect"
        static let signOut = "Log out"
    }

    enum Reflect {
        static func segmentTab(_ title: String, isSelected: Bool) -> String {
            isSelected ? "\(title), selected" : title
        }
        static func like(isLiked: Bool, count: Int) -> String {
            let countPhrase = count == 1 ? "1 like" : "\(count) likes"
            return isLiked ? "Unlike. \(countPhrase)" : "Like. \(countPhrase)"
        }
        static let tryAgain = "Try again"
        static let scrollPosts = "Swipe up or down to move between reflections"
    }
}

extension RandomAyahPayload {
    @MainActor
    func spokenAccessibilitySummary(includeTranslation: Bool) -> String {
        var parts: [String] = []
        if let key = verseKey {
            parts.append(ShareVerseCard.humanLabel(for: key))
        } else {
            parts.append("Quran verse")
        }
        if includeTranslation,
           let text = translations?.first?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           text.isEmpty == false {
            parts.append("Translation: \(text)")
        } else {
            parts.append("Arabic text with tajweed colors is shown on screen")
        }
        return parts.joined(separator: ". ")
    }
}

extension ReflectFeedPost {
    @MainActor
    var spokenAccessibilitySummary: String {
        var parts: [String] = []
        if let name = author?.displayName, name.isEmpty == false {
            parts.append("Reflection by \(name)")
        }
        if let key = references?.first?.verseKey {
            parts.append(ShareVerseCard.humanLabel(for: key))
        }
        if let body = body?.trimmingCharacters(in: .whitespacesAndNewlines), body.isEmpty == false {
            parts.append(body)
        }
        return parts.isEmpty ? "Reflection post" : parts.joined(separator: ". ")
    }
}

extension QuranChapter {
    var spokenAccessibilitySummary: String {
        var parts: [String] = [
            "Surah \(id), \(displayComplexName)"
        ]
        if displayTranslatedName.isEmpty == false {
            parts.append(displayTranslatedName)
        }
        if revelationLabel.isEmpty == false {
            parts.append("Revealed in \(revelationLabel)")
        }
        if let versesCountLabel {
            parts.append(versesCountLabel)
        }
        return parts.joined(separator: ". ")
    }
}

extension View {
    func alKhatibAccessibility(label: String, hint: String? = nil) -> some View {
        modifier(AlKhatibAccessibilityModifier(label: label, hint: hint))
    }
}

private struct AlKhatibAccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?

    func body(content: Content) -> some View {
        if let hint, hint.isEmpty == false {
            content
                .accessibilityLabel(label)
                .accessibilityHint(hint)
        } else {
            content.accessibilityLabel(label)
        }
    }
}
