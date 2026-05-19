//
//  ShareVerseCard.swift
//  Al-Khatib
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

internal import UIKit

struct ShareVerseCard {
    @MainActor
    static func presentPrepared(text: String) {
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = windowScene.windows.first?.rootViewController else { return }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = root.view
            popover.sourceRect = CGRect(x: root.view.bounds.midX, y: root.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        root.present(activityVC, animated: true)
    }

    static func humanLabel(for verseKey: String) -> String {
        VerseKeyFormat.humanLabel(for: verseKey)
    }
}
