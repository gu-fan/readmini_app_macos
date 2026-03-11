import Foundation
import SwiftData

@MainActor
final class SwiftDataReaderRepository: ReaderRepository {
    private let modelContext: ModelContext
    private let feedFetcher: FeedFetching
    private let feedParser: FeedParsing

    init(
        modelContext: ModelContext,
        feedFetcher: FeedFetching,
        feedParser: FeedParsing
    ) {
        self.modelContext = modelContext
        self.feedFetcher = feedFetcher
        self.feedParser = feedParser
    }

    func fetchSubscriptions() throws -> [Subscription] {
        let descriptor = FetchDescriptor<SubscriptionRecord>(
            sortBy: [SortDescriptor(\.addedAt, order: .forward)]
        )
        return try modelContext.fetch(descriptor).map { record in
            Subscription(
                id: record.id,
                title: record.title,
                url: record.url,
                description: record.feedDescription,
                addedAt: record.addedAt,
                lastRefreshedAt: record.lastRefreshedAt
            )
        }
    }

    func fetchArticles(subscriptionID: UUID?) throws -> [Article] {
        let predicate: Predicate<ArticleRecord>?
        if let subscriptionID {
            predicate = #Predicate<ArticleRecord> { article in
                article.subscriptionID == subscriptionID
            }
        } else {
            predicate = nil
        }

        var descriptor = FetchDescriptor<ArticleRecord>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse), SortDescriptor(\.title, order: .forward)]
        )
        descriptor.fetchLimit = 500
        return try modelContext.fetch(descriptor).map { record in
            let summaryHTML = record.summaryHTML.isEmpty ? record.contentHTML : record.summaryHTML
            let contentHTML = record.contentHTML.isEmpty ? record.summaryHTML : record.contentHTML
            return Article(
                id: record.id,
                subscriptionID: record.subscriptionID,
                feedTitle: record.feedTitle,
                title: record.title,
                link: record.link,
                firstImageURL: record.firstImageURL,
                summaryHTML: summaryHTML,
                contentHTML: contentHTML,
                summaryText: HTMLSupport.stripHTML(summaryHTML),
                contentText: HTMLSupport.stripHTML(contentHTML),
                author: record.author,
                publishedAt: record.publishedAt
            )
        }
    }

    func addSubscription(url: String) async throws {
        let normalized = try normalize(urlString: url)
        if try findSubscription(byURL: normalized) != nil {
            throw ReaderRepositoryError.duplicateSubscription
        }

        let payload = try await fetchPayload(from: normalized)
        let subscription = SubscriptionRecord(
            url: normalized,
            title: payload.title,
            feedDescription: payload.description,
            addedAt: .now,
            lastRefreshedAt: .now
        )
        modelContext.insert(subscription)
        try save()
        try upsertArticles(for: subscription, payload: payload)
    }

    func removeSubscription(id: UUID) throws {
        guard let subscription = try findSubscription(byID: id) else {
            return
        }

        let descriptor = FetchDescriptor<ArticleRecord>(
            predicate: #Predicate<ArticleRecord> { article in
                article.subscriptionID == id
            }
        )
        let articles = try modelContext.fetch(descriptor)
        for article in articles {
            modelContext.delete(article)
        }
        modelContext.delete(subscription)
        try save()
    }

    func refreshAll() async throws {
        let subscriptions = try modelContext.fetch(FetchDescriptor<SubscriptionRecord>())
        for subscription in subscriptions {
            try await refresh(record: subscription)
        }
    }

    func refreshSubscription(id: UUID) async throws {
        guard let subscription = try findSubscription(byID: id) else {
            return
        }
        try await refresh(record: subscription)
    }

    func importDefaultFeeds(_ feeds: [DefaultFeedSource]) async -> [ImportResult] {
        var results: [ImportResult] = []
        for feed in feeds {
            do {
                try await addSubscription(url: feed.url)
                results.append(ImportResult(feed: feed, wasImported: true, error: nil))
            } catch ReaderRepositoryError.duplicateSubscription {
                results.append(ImportResult(feed: feed, wasImported: false, error: nil))
            } catch {
                results.append(ImportResult(feed: feed, wasImported: false, error: error.localizedDescription))
            }
        }
        return results
    }

    private func refresh(record: SubscriptionRecord) async throws {
        let payload = try await fetchPayload(from: record.url)
        record.title = payload.title
        record.feedDescription = payload.description
        record.lastRefreshedAt = .now
        try upsertArticles(for: record, payload: payload)
    }

    private func fetchPayload(from urlString: String) async throws -> FeedPayload {
        guard let url = URL(string: urlString) else {
            throw ReaderRepositoryError.invalidURL
        }
        let data = try await feedFetcher.fetchFeed(from: url)
        return try feedParser.parse(data: data)
    }

    private func upsertArticles(for subscription: SubscriptionRecord, payload: FeedPayload) throws {
        let existing = try modelContext.fetch(FetchDescriptor<ArticleRecord>())
        let existingByKey = Dictionary(uniqueKeysWithValues: existing.map { ($0.stableKey, $0) })

        for entry in payload.entries {
            let stableKey = Self.makeStableKey(subscriptionID: subscription.id, entry: entry)
            if let article = existingByKey[stableKey] {
                article.feedTitle = payload.title
                article.title = entry.title
                article.link = entry.link
                article.firstImageURL = entry.firstImageURL
                article.summaryHTML = entry.summaryHTML
                article.contentHTML = entry.contentHTML
                article.author = entry.author
                article.publishedAt = entry.publishedAt
            } else {
                let article = ArticleRecord(
                    stableKey: stableKey,
                    subscriptionID: subscription.id,
                    feedTitle: payload.title,
                    title: entry.title,
                    link: entry.link,
                    firstImageURL: entry.firstImageURL,
                    summaryHTML: entry.summaryHTML,
                    contentHTML: entry.contentHTML,
                    author: entry.author,
                    publishedAt: entry.publishedAt
                )
                modelContext.insert(article)
            }
        }

        try save()
    }

    private func normalize(urlString: String) throws -> String {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
            throw ReaderRepositoryError.invalidURL
        }
        return url.absoluteString
    }

    private func findSubscription(byID id: UUID) throws -> SubscriptionRecord? {
        let descriptor = FetchDescriptor<SubscriptionRecord>(
            predicate: #Predicate<SubscriptionRecord> { subscription in
                subscription.id == id
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func findSubscription(byURL url: String) throws -> SubscriptionRecord? {
        let descriptor = FetchDescriptor<SubscriptionRecord>(
            predicate: #Predicate<SubscriptionRecord> { subscription in
                subscription.url == url
            }
        )
        return try modelContext.fetch(descriptor).first
    }

    private func save() throws {
        try modelContext.save()
    }

    private static func makeStableKey(subscriptionID: UUID, entry: FeedEntry) -> String {
        if !entry.link.isEmpty {
            return "\(subscriptionID.uuidString)|\(entry.link)"
        }

        let timestamp = entry.publishedAt?.timeIntervalSince1970.description ?? "no-date"
        return "\(subscriptionID.uuidString)|\(entry.title)|\(timestamp)"
    }
}
