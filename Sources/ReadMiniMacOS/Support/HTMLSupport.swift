import AppKit
import Foundation

enum HTMLSupport {
    static func firstImageURL(in html: String) -> String? {
        let pattern = #"<img[^>]+src\s*=\s*["']([^"']+)["']"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }

        let range = NSRange(html.startIndex..<html.endIndex, in: html)
        guard
            let match = regex.firstMatch(in: html, options: [], range: range),
            let imageRange = Range(match.range(at: 1), in: html)
        else {
            return nil
        }

        return String(html[imageRange])
    }

    static func htmlToAttributedString(_ html: String, baseFontSize: Double) -> AttributedString {
        guard !html.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return AttributedString("")
        }

        let wrapped = """
        <html>
          <head>
            <style>
              body { font-family: -apple-system; font-size: \(baseFontSize)px; line-height: 1.6; }
              img { max-width: 100%; }
              pre { white-space: pre-wrap; }
            </style>
          </head>
          <body>\(html)</body>
        </html>
        """

        guard let data = wrapped.data(using: .utf8) else {
            return AttributedString(stripHTML(html))
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        guard let nsAttributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil),
              let attributedString = try? AttributedString(nsAttributedString, including: \.appKit)
        else {
            return AttributedString(stripHTML(html))
        }

        return attributedString
    }

    static func stripHTML(_ html: String) -> String {
        guard let data = html.data(using: .utf8) else {
            return html
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue,
        ]

        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }
}
