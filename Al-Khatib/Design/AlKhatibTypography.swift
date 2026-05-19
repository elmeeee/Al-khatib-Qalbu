//
//  AlKhatibTypography.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import CoreText
internal import UIKit

enum AlKhatibTypography {
    @MainActor
    static func quranArabic(size: CGFloat) -> Font {
        return FontResolver.quranFont(size: size)
    }

    @MainActor
    static func quranArabicUIFont(size: CGFloat) -> UIFont {
        return FontResolver.quranUIFont(size: size)
    }

    @MainActor
    static func verseArabicHTMLBaseDirectory() -> URL? {
        VerseArabicHTMLFontPreparer.shared.folderURLIfReady()
    }

    nonisolated static let verseWebFontRelativeFileName = "tajweed_web.ttf"
}

private struct VerseArabicHTMLFontPreparer {
    static let shared = Self()

    @MainActor
    func folderURLIfReady() -> URL? {
        guard let cachesRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        guard let asset = NSDataAsset(name: "tajweed_font"), asset.data.isEmpty == false else {
            return nil
        }

        let dir = cachesRoot.appendingPathComponent("AlKhatibWebFonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let fontCopy = dir.appendingPathComponent(AlKhatibTypography.verseWebFontRelativeFileName, isDirectory: false)
        if !FileManager.default.fileExists(atPath: fontCopy.path) {
            do {
                try asset.data.write(to: fontCopy, options: [.atomic])
            } catch {
                return nil
            }
        }
        return dir
    }
}

@MainActor
private enum FontResolver {
    private static let quranAssetCandidates = ["tajweed_font"]
    private static var cachedFontName: String?

    static func quranFont(size: CGFloat) -> Font {
        if cachedFontName == nil {
            cachedFontName = resolveAndRegisterFontName()
        }
        if let name = cachedFontName {
            return .custom(name, size: size)
        }
        return .system(size: size)
    }

    static func quranUIFont(size: CGFloat) -> UIFont {
        if cachedFontName == nil {
            cachedFontName = resolveAndRegisterFontName()
        }
        if let name = cachedFontName, let uiFont = UIFont(name: name, size: size) {
            return uiFont
        }
        return UIFont.systemFont(ofSize: size)
    }

    private static func resolveAndRegisterFontName() -> String? {
        for assetName in quranAssetCandidates {
            if let name = registerFontFromDataAsset(assetName) {
                return name
            }
        }
        return nil
    }

    private static func registerFontFromDataAsset(_ assetName: String) -> String? {
        guard let dataAsset = NSDataAsset(name: assetName) else {
            return nil
        }

        let fontData = dataAsset.data as CFData
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromData(fontData) as? [CTFontDescriptor],
              let firstDescriptor = descriptors.first else {
            return nil
        }

        let postScriptName = CTFontDescriptorCopyAttribute(firstDescriptor, kCTFontNameAttribute) as? String
        CTFontManagerRegisterFontDescriptors(
            descriptors as CFArray,
            CTFontManagerScope.process,
            true,
            nil
        )

        return postScriptName
    }
}
