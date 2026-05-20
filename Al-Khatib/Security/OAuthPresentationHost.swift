//
//  OAuthPresentationHost.swift
//  Al-Khatib
//

internal import UIKit

@MainActor
enum OAuthPresentationHost {
    private static var presentationWindow: UIWindow?

    static func activate() {
        guard presentationWindow == nil else { return }
        guard let scene = foregroundWindowScene else { return }

        let window = UIWindow(windowScene: scene)
        window.windowLevel = UIWindow.Level.alert + 1
        window.backgroundColor = .clear

        let root = UIViewController()
        root.view.backgroundColor = .clear
        window.rootViewController = root
        window.isHidden = false
        presentationWindow = window
    }

    static func deactivate() {
        presentationWindow?.isHidden = true
        presentationWindow?.rootViewController = nil
        presentationWindow = nil
    }

    static var anchor: UIWindow? {
        presentationWindow
    }

    private static var foregroundWindowScene: UIWindowScene? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        if let active = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return active
        }
        return scenes.first
    }
}
