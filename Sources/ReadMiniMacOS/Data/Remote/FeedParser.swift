import Foundation

struct XMLFeedParsing: FeedParsing {
    func parse(data: Data) throws -> FeedPayload {
        let document = try XMLDocument(data: data, options: [.nodePreserveAll])
        guard let root = document.rootElement()?.name?.lowercased() else {
            throw ReaderRepositoryError.invalidFeed
        }

        if root == "rss" || root.contains("rdf") {
            return try parseRSS(document: document)
        }

        if root.contains("feed") {
            return try parseAtom(document: document)
        }

        throw ReaderRepositoryError.invalidFeed
    }

    private func parseRSS(document: XMLDocument) throws -> FeedPayload {
        let channels = try document.nodes(forXPath: "/*[local-name()='rss']/*[local-name()='channel']")
        guard let channel = channels.first as? XMLElement else {
            throw ReaderRepositoryError.invalidFeed
        }

        let title = text(in: channel, path: "./*[local-name()='title']") ?? "未命名订阅"
        let description = text(in: channel, path: "./*[local-name()='description']") ?? ""
        let items = try channel.nodes(forXPath: "./*[local-name()='item']").compactMap { $0 as? XMLElement }

        let entries = items.compactMap { item in
            makeRSSEntry(from: item)
        }

        if entries.isEmpty {
            throw ReaderRepositoryError.emptyFeed
        }

        return FeedPayload(title: title, description: description, entries: entries)
    }

    private func parseAtom(document: XMLDocument) throws -> FeedPayload {
        guard let feed = document.rootElement() else {
            throw ReaderRepositoryError.invalidFeed
        }

        let title = text(in: feed, path: "./*[local-name()='title']") ?? "未命名订阅"
        let description = text(in: feed, path: "./*[local-name()='subtitle']") ?? ""
        let items = try feed.nodes(forXPath: "./*[local-name()='entry']").compactMap { $0 as? XMLElement }
        let entries = items.compactMap { item in
            makeAtomEntry(from: item)
        }

        if entries.isEmpty {
            throw ReaderRepositoryError.emptyFeed
        }

        return FeedPayload(title: title, description: description, entries: entries)
    }

    private func makeRSSEntry(from item: XMLElement) -> FeedEntry? {
        let title = text(in: item, path: "./*[local-name()='title']")?.nilIfBlank ?? "Untitled"
        let link = text(in: item, path: "./*[local-name()='link']")?.nilIfBlank ?? ""
        let summaryHTML = text(in: item, path: "./*[local-name()='description']") ?? ""
        let contentHTML = text(in: item, path: "./*[local-name()='encoded']") ?? summaryHTML
        let author = text(in: item, path: "./*[local-name()='creator']") ??
            text(in: item, path: "./*[local-name()='author']") ??
            ""
        let publishedAt = parseDate(
            text(in: item, path: "./*[local-name()='pubDate']") ??
            text(in: item, path: "./*[local-name()='date']")
        )
        let firstImageURL = HTMLSupport.firstImageURL(in: contentHTML.isEmpty ? summaryHTML : contentHTML)

        if link.isEmpty && summaryHTML.isEmpty && contentHTML.isEmpty {
            return nil
        }

        return FeedEntry(
            title: title,
            link: link,
            summaryHTML: summaryHTML,
            contentHTML: contentHTML,
            author: author,
            publishedAt: publishedAt,
            firstImageURL: firstImageURL
        )
    }

    private func makeAtomEntry(from item: XMLElement) -> FeedEntry? {
        let title = text(in: item, path: "./*[local-name()='title']")?.nilIfBlank ?? "Untitled"
        let link = atomLink(in: item) ?? ""
        let summaryHTML = text(in: item, path: "./*[local-name()='summary']") ?? ""
        let contentHTML = text(in: item, path: "./*[local-name()='content']") ?? summaryHTML
        let author = text(in: item, path: "./*[local-name()='author']/*[local-name()='name']") ?? ""
        let publishedAt = parseDate(
            text(in: item, path: "./*[local-name()='published']") ??
            text(in: item, path: "./*[local-name()='updated']")
        )
        let firstImageURL = HTMLSupport.firstImageURL(in: contentHTML.isEmpty ? summaryHTML : contentHTML)

        if link.isEmpty && summaryHTML.isEmpty && contentHTML.isEmpty {
            return nil
        }

        return FeedEntry(
            title: title,
            link: link,
            summaryHTML: summaryHTML,
            contentHTML: contentHTML,
            author: author,
            publishedAt: publishedAt,
            firstImageURL: firstImageURL
        )
    }

    private func text(in element: XMLElement, path: String) -> String? {
        let node = try? element.nodes(forXPath: path).first
        if let attribute = node {
            return attribute.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return node?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func atomLink(in item: XMLElement) -> String? {
        if let alternate = try? item.nodes(forXPath: "./*[local-name()='link'][@rel='alternate']/@href").first?.stringValue,
           let value = alternate.nilIfBlank {
            return value
        }

        return try? item.nodes(forXPath: "./*[local-name()='link'][1]/@href").first?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func parseDate(_ text: String?) -> Date? {
        guard let value = text?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }

        let preciseISO8601 = ISO8601DateFormatter()
        preciseISO8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = preciseISO8601.date(from: value) {
            return date
        }

        let iso8601Parser = ISO8601DateFormatter()
        iso8601Parser.formatOptions = [.withInternetDateTime]
        if let date = iso8601Parser.date(from: value) {
            return date
        }

        for pattern in [
            "EEE, dd MMM yyyy HH:mm:ss Z",
            "dd MMM yyyy HH:mm:ss Z",
            "EEE, dd MMM yyyy HH:mm Z",
        ] {
            let parser = DateFormatter()
            parser.locale = Locale(identifier: "en_US_POSIX")
            parser.dateFormat = pattern
            if let date = parser.date(from: value) {
                return date
            }
        }

        return nil
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
