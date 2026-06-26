//
//  HTMLContentWebView.swift
//  Sāat
//
//  Created by Elmee on 25/04/2026.
//  Copyright © 2026 Elmee. All rights reserved.
//

import SwiftUI
import WebKit
internal import UIKit

enum HTMLContentStyle {
    case article
    case tafsirReader
    case verseCard
    case verseCardOnDark

    var isVerseCard: Bool {
        switch self {
        case .verseCard, .verseCardOnDark: true
        default: false
        }
    }
}

struct HTMLContentWebView: UIViewRepresentable {
    let htmlFragment: String
    var style: HTMLContentStyle = .article
    var rendersTajweedHTML: Bool = false
    var fontScale: Double = 1.0
    var contentHeight: Binding<CGFloat>?

    init(
        htmlFragment: String,
        style: HTMLContentStyle = .article,
        rendersTajweedHTML: Bool = false,
        fontScale: Double = 1.0,
        contentHeight: Binding<CGFloat>? = nil
    ) {
        self.htmlFragment = htmlFragment
        self.style = style
        self.rendersTajweedHTML = rendersTajweedHTML
        self.fontScale = fontScale
        self.contentHeight = contentHeight
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(heightBinding: contentHeight, style: style)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = .clear
        }
        webView.navigationDelegate = context.coordinator
        context.coordinator.webViewRef = webView
        configureScroll(webView, style: style)
        applyVerseCardInteractionPolicy(webView, style: style)
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        context.coordinator.heightBinding = contentHeight
        context.coordinator.style = style
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        if #available(iOS 15.0, *) {
            webView.underPageBackgroundColor = .clear
        }
        configureScroll(webView, style: style)
        applyVerseCardInteractionPolicy(webView, style: style)
        if style.isVerseCard, let target = contentHeight?.wrappedValue, target > 0 {
            resizeVerseWebView(webView, height: target)
        }
        let baseDirectory: URL?
        let embedFont: Bool
        if style.isVerseCard {
            baseDirectory = AlKhatibTypography.verseArabicHTMLBaseDirectory()
            embedFont = rendersTajweedHTML && baseDirectory != nil
        } else {
            baseDirectory = nil
            embedFont = false
        }

        let key = ContentLoadSignature(
            htmlFragment: htmlFragment,
            style: style,
            rendersTajweedHTML: rendersTajweedHTML,
            fontScale: fontScale,
            embedVerseWebFont: embedFont,
            baseURLPath: baseDirectory?.standardizedFileURL.path ?? ""
        )
        guard context.coordinator.lastSignature != key else { return }
        context.coordinator.lastSignature = key

        if style.isVerseCard, let binding = contentHeight {
            let placeholder = AyahArabicWebBlock.placeholderHeight
            DispatchQueue.main.async {
                binding.wrappedValue = placeholder
            }
        }

        let html = Self.document(
            from: htmlFragment,
            style: style,
            embedVerseWebFont: embedFont,
            fontScale: fontScale
        )
        let loadBase = baseDirectory ?? URL(string: "about:blank")
        webView.loadHTMLString(html, baseURL: loadBase)
    }

    private func configureScroll(_ webView: WKWebView, style: HTMLContentStyle) {
        switch style {
        case .article, .tafsirReader:
            webView.scrollView.isScrollEnabled = true
            webView.scrollView.bounces = true
            webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        case .verseCard, .verseCardOnDark:
            webView.scrollView.isScrollEnabled = false
            webView.scrollView.bounces = false
            webView.scrollView.contentInsetAdjustmentBehavior = .never
        }
    }

    private func applyVerseCardInteractionPolicy(_ webView: WKWebView, style: HTMLContentStyle) {
        guard style.isVerseCard else { return }
        webView.isUserInteractionEnabled = false
        webView.clipsToBounds = false
        webView.scrollView.clipsToBounds = false
        webView.scrollView.isUserInteractionEnabled = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
    }

    private func resizeVerseWebView(_ webView: WKWebView, height: CGFloat) {
        Self.applyVerseWebViewFrame(webView, height: height)
    }

    fileprivate static func verseLayoutWidth(for webView: WKWebView) -> CGFloat? {
        if webView.bounds.width >= 1 {
            return webView.bounds.width
        }
        if let superviewWidth = webView.superview?.bounds.width, superviewWidth >= 1 {
            return superviewWidth
        }
        if let screen = webView.window?.windowScene?.screen {
            let horizontalInset: CGFloat = 72
            return max(screen.bounds.width - horizontalInset, 1)
        }
        return nil
    }

    fileprivate static func applyVerseWebViewFrame(_ webView: WKWebView, height: CGFloat) {
        guard let width = verseLayoutWidth(for: webView) else { return }
        let size = CGSize(width: width, height: height)
        webView.frame = CGRect(origin: .zero, size: size)
        webView.scrollView.frame = CGRect(origin: .zero, size: size)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        weak var webViewRef: WKWebView?
        var heightBinding: Binding<CGFloat>?
        var style: HTMLContentStyle
        fileprivate var lastSignature: ContentLoadSignature?

        init(heightBinding: Binding<CGFloat>?, style: HTMLContentStyle) {
            self.heightBinding = heightBinding
            self.style = style
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard style.isVerseCard, let binding = heightBinding else { return }
            scheduleVerseCardHeightMeasurement(webView: webView, binding: binding)
        }

        private func scheduleVerseCardHeightMeasurement(webView: WKWebView, binding: Binding<CGFloat>) {
            measureVerseCardHeight(webView: webView, binding: binding)
            for delay in [0.08, 0.2, 0.45, 0.9, 1.4] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    self.measureVerseCardHeight(webView: webView, binding: binding)
                }
            }
        }

        private func measureVerseCardHeight(webView: WKWebView, binding: Binding<CGFloat>) {
            guard HTMLContentWebView.verseLayoutWidth(for: webView) != nil else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self, weak webView] in
                    guard let self, let webView else { return }
                    self.measureVerseCardHeight(webView: webView, binding: binding)
                }
                return
            }

            resizeVerseWebView(webView, height: 12_000)

            let script = """
            (async function() {
              if (document.fonts && document.fonts.ready) { await document.fonts.ready; }
              await new Promise(function(resolve) {
                requestAnimationFrame(function() { requestAnimationFrame(resolve); });
              });
              var root = document.getElementById('verse-measure') || document.body;
              if (!root) return 0;
              var top = root.getBoundingClientRect().top;
              var maxBottom = root.getBoundingClientRect().bottom;
              root.querySelectorAll('*').forEach(function(el) {
                var r = el.getBoundingClientRect();
                if (r.height > 0) { maxBottom = Math.max(maxBottom, r.bottom); }
              });
              return Math.ceil(Math.max(
                maxBottom - top,
                root.scrollHeight,
                root.offsetHeight,
                document.body.scrollHeight,
                document.documentElement.scrollHeight
              ));
            })();
            """
            webView.evaluateJavaScript(script) { [weak webView] result, _ in
                guard let webView else { return }
                let jsHeight: CGFloat
                if let n = result as? NSNumber {
                    jsHeight = CGFloat(truncating: n)
                } else if let cg = result as? CGFloat {
                    jsHeight = cg
                } else {
                    jsHeight = 120
                }
                let clamped = min(max(jsHeight + 24, 72), 4000)
                DispatchQueue.main.async { [weak self] in
                    var txn = Transaction()
                    txn.animation = nil
                    withTransaction(txn) {
                        binding.wrappedValue = clamped
                    }
                    self?.resizeVerseWebView(webView, height: clamped)
                }
            }
        }

        private func resizeVerseWebView(_ webView: WKWebView, height: CGFloat) {
            HTMLContentWebView.applyVerseWebViewFrame(webView, height: height)
        }
    }

    fileprivate struct ContentLoadSignature: Equatable {
        let htmlFragment: String
        let style: HTMLContentStyle
        let rendersTajweedHTML: Bool
        let fontScale: Double
        let embedVerseWebFont: Bool
        let baseURLPath: String
    }

    private static func document(
        from raw: String,
        style: HTMLContentStyle,
        embedVerseWebFont: Bool = false,
        fontScale: Double = 1.0
    ) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.range(of: #"^\s*<(html\b|!DOCTYPE\s)"#, options: [.regularExpression, .caseInsensitive]) != nil {
            return trimmed
        }
        return wrappedFragment(
            trimmed,
            style: style,
            embedVerseWebFont: embedVerseWebFont,
            fontScale: fontScale
        )
    }

    private static func wrappedFragment(
        _ body: String,
        style: HTMLContentStyle,
        embedVerseWebFont: Bool,
        fontScale: Double
    ) -> String {
        let extraCSS: String
        switch style {
        case .article:
            extraCSS = """
                body {
                  font-family: -apple-system, system-ui, "Segoe UI", Roboto, sans-serif;
                  font-size: 16px;
                  line-height: 1.55;
                  padding: 12px 16px 28px;
                  color: CanvasText;
                }
            """

        case .tafsirReader:
            extraCSS = Self.tafsirReaderBodyCSS()

        case .verseCard, .verseCardOnDark:
            extraCSS = verseCardCSS(
                onDark: style == .verseCardOnDark,
                embedVerseWebFont: embedVerseWebFont,
                fontScale: fontScale
            )
        }

        let (lang, dir) = htmlLocale(for: style)
        let prose = proseRules(for: style)
        let colorSchemeMeta: String =
            style.isVerseCard ? "light" : "light dark"
        let colorSchemeCSS: String =
            style.isVerseCard
            ? ":root { color-scheme: light only; }"
            : ":root { color-scheme: light dark; }"

        return """
        <!DOCTYPE html>
        <html lang="\(lang)" dir="\(dir)">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
          <meta name="color-scheme" content="\(colorSchemeMeta)">
          <style>
            \(colorSchemeCSS)
            html, body {
              margin: 0;
              padding: 0;
            }
            \(extraCSS)
            \(prose)
          </style>
        </head>
        <body>\(verseCardBodyMarkup(body, style: style))</body>
        </html>
        """
    }

    private static func verseCardBodyMarkup(_ body: String, style: HTMLContentStyle) -> String {
        guard style.isVerseCard else { return body }
        return "<div id=\"verse-measure\">\(body)</div>"
    }

    private static func htmlLocale(for style: HTMLContentStyle) -> (lang: String, dir: String) {
        switch style {
        case .verseCard, .verseCardOnDark:
            ("ar", "rtl")
        case .tafsirReader, .article:
            ("en", "ltr")
        }
    }

    private static func verseCardCSS(
        onDark: Bool,
        embedVerseWebFont: Bool,
        fontScale: Double
    ) -> String {
        let scale = min(max(fontScale, 0.85), 1.45) * QuranVerseArabic.webFontSizeScale
        let minPx = 21 * scale
        let maxPx = 28 * scale
        let vw = 4.8 * scale
        let lineHeight = QuranVerseArabic.webLineHeight
        let fontFace: String = {
            guard embedVerseWebFont else { return "" }
            let file = AlKhatibTypography.verseWebFontRelativeFileName
            return """

            @font-face {
              font-family: 'AlKhatibQuranWeb';
              src: url('\(file)') format('truetype');
              font-weight: normal;
              font-style: normal;
              font-display: swap;
            }
            """
        }()
        let arabicFontStack = QuranVerseArabic.webArabicFontStack(embeddingTajweedWebFont: embedVerseWebFont)
        let bodyColor = onDark ? "#FFFFFF" : "#1D1D1F"
        let endGold = onDark ? "rgba(212, 175, 55, 0.95)" : "rgba(148, 80, 5, 0.95)"
        let tajweed: String = {
            let base = """
                tajweed, span[class*="tajweed"] {
                  display: inline;
                  color: inherit;
                  font-family: inherit;
                }
            """
            if onDark {
                return base + """
                .ghunnah, [class*="ghunnah"] { color: #81C784; }
                .slnt, [class*="slnt"] { color: #B0BEC5; }
                .madda_normal, [class*="madda_normal"] { color: #9FA8DA; }
                .madda_permissible, [class*="madda_permissible"] { color: #CE93D8; }
                .madda_obligatory, [class*="madda_obligatory"] { color: #E1BEE7; }
                .qalaqah, [class*="qalaqah"] { color: #FFAB91; }
                .idgham_ghunnah, [class*="idgham_ghunnah"] { color: #80CBC4; }
                .ikhafa, [class*="ikhafa"], .ikhafa_shafawi, [class*="ikhafa_shafawi"] { color: #80DEEA; }
                .ham_wasl, [class*="ham_wasl"] { color: #AED581; }
                .laam_shamsiyah, [class*="laam_shamsiyah"] { color: #FFCC80; }
                .laam_qamariyah, [class*="laam_qamariyah"] { color: #CE93D8; }
                .iqlab, [class*="iqlab"] { color: #80CBC4; }
                """
            }
            return base + """
                .ghunnah, [class*="ghunnah"] { color: #2E7D32; }
                .slnt, [class*="slnt"] { color: #5C6F7A; }
                .madda_normal, [class*="madda_normal"] { color: #3949AB; }
                .madda_permissible, [class*="madda_permissible"] { color: #6A1B9A; }
                .madda_obligatory, [class*="madda_obligatory"] { color: #7B1FA2; }
                .qalaqah, [class*="qalaqah"] { color: #D84315; }
                .idgham_ghunnah, [class*="idgham_ghunnah"] { color: #00897B; }
                .ikhafa, [class*="ikhafa"], .ikhafa_shafawi, [class*="ikhafa_shafawi"] { color: #00838F; }
                .ham_wasl, [class*="ham_wasl"] { color: #558B2F; }
                .laam_shamsiyah, [class*="laam_shamsiyah"] { color: #E65100; }
                .laam_qamariyah, [class*="laam_qamariyah"] { color: #6A1B9A; }
                .iqlab, [class*="iqlab"] { color: #00897B; }
                """
        }()
        return """
            \(fontFace)
            html, body {
              background: transparent !important;
              color-scheme: light only;
              overflow: visible !important;
            }
            #verse-measure {
              display: block;
              width: 100%;
              overflow: visible;
              box-sizing: border-box;
            }
            body {
              direction: rtl;
              text-align: center;
              unicode-bidi: plaintext;
              font-family: \(arabicFontStack);
              font-size: clamp(\(String(format: "%.1f", minPx))px, \(String(format: "%.1f", vw))vw, \(String(format: "%.1f", maxPx))px);
              line-height: \(String(format: "%.2f", lineHeight));
              padding: 4px 0 14px;
              color: \(bodyColor);
              -webkit-hyphens: none;
              margin: 0;
              overflow: visible;
              -webkit-font-smoothing: antialiased;
            }
            span.end { opacity: 0.95; font-weight: 600; color: \(bodyColor); }
            .ayah-end-symbol {
              display: inline-grid;
              place-items: center;
              white-space: nowrap;
              unicode-bidi: embed;
              font-family: \(arabicFontStack);
              color: \(endGold);
              margin-inline-start: 0.3em;
              width: 1.42em;
              height: 1.42em;
              font-size: 1em;
              vertical-align: -0.12em;
              line-height: 1;
              font-feature-settings: "liga" 1, "kern" 1;
            }
            .ayah-end-rosette {
              grid-area: 1 / 1;
              font-size: 1.42em;
              line-height: 1;
              color: \(endGold);
            }
            .ayah-end-number {
              grid-area: 1 / 1;
              font-size: 0.56em;
              line-height: 1;
              font-weight: 700;
              transform: translateY(-0.01em);
              color: \(endGold);
            }
            \(tajweed)
            .end { color: \(endGold); }
        """
    }

    private static func proseRules(for style: HTMLContentStyle) -> String {
        switch style {
        case .tafsirReader:
            return """
                ul, ol { margin: 0 0 1.05em; padding-inline-start: 1.35em; }
                li { margin: 0.25em 0; }
                a { color: LinkText; word-break: break-word; text-decoration: underline; text-underline-offset: 2px; }
                img, video { max-width: 100%; height: auto; border-radius: 8px; }
                table { border-collapse: collapse; max-width: 100%; font-size: 0.92em; }
                td, th { border: 1px solid rgba(128,128,128,0.22); padding: 8px 10px; }
                sup, sub { font-size: 0.75em; }
                code { font-family: ui-monospace, Menlo, monospace; font-size: 0.9em; }
            """
        case .article, .verseCard, .verseCardOnDark:
            return """
                p { margin: 0 0 12px; }
                div { margin-bottom: 8px; }
                h1, h2, h3, h4 { margin: 18px 0 10px; font-weight: 600; line-height: 1.25; }
                ul, ol { margin: 0 0 12px; padding-inline-start: 1.25em; }
                a { color: LinkText; word-break: break-word; }
                img, video { max-width: 100%; height: auto; }
                blockquote {
                  margin: 12px 0;
                  padding: 10px 14px;
                  border-inline-start: 3px solid rgba(128,128,128,0.35);
                  background: rgba(128,128,128,0.08);
                }
                table { border-collapse: collapse; max-width: 100%; }
                td, th { border: 1px solid rgba(128,128,128,0.25); padding: 6px 8px; }
            """
        }
    }

    private static func tafsirReaderBodyCSS() -> String {
        """
        html {
          scroll-behavior: smooth;
          -webkit-text-size-adjust: 100%;
        }
        body {
          font-family: ui-serif, -apple-system-ui-serif, "Iowan Old Style", "Palatino Linotype", Palatino, Georgia, serif;
          font-size: clamp(17px, 2.8vw, 19px);
          line-height: 1.72;
          letter-spacing: -0.01em;
          padding: 4px min(22px, 5vw) max(32px, env(safe-area-inset-bottom, 20px));
          margin: 0 auto;
          max-width: 40rem;
          color: CanvasText;
          orphans: 2;
          widows: 2;
          text-align: start;
          direction: ltr;
        }
        p { margin: 0 0 1.05em; }
        p:last-child { margin-bottom: 0; }
        h1, h2, h3, h4 {
          font-family: -apple-system, system-ui, "SF Pro Display", "SF Pro Text", sans-serif;
          color: CanvasText;
          margin: 1.35em 0 0.6em;
          font-weight: 650;
          line-height: 1.28;
          letter-spacing: -0.02em;
        }
        h1 { font-size: 1.35em; margin-top: 0.35em; }
        h2 { font-size: 1.22em; }
        h3, h4 { font-size: 1.06em; }
        strong { font-weight: 650; }
        em { font-style: italic; }
        blockquote {
          margin: 1.05em 0;
          padding: 12px 16px;
          border-inline-start: 3px solid rgba(6, 78, 59, 0.42);
          background: rgba(6, 78, 59, 0.06);
          border-radius: 0 10px 10px 0;
        }
        @media (prefers-color-scheme: dark) {
          blockquote {
            border-inline-start-color: rgba(45, 212, 191, 0.45);
            background: rgba(45, 212, 191, 0.08);
          }
        }
        """
    }
}
