import Foundation
import SwiftData
import Testing
@testable import ReadMiniMacOS

@MainActor
struct ReaderRepositoryTests {
    @Test
    func addSubscriptionStoresFeedAndArticles() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataReaderRepository(
            modelContext: ModelContext(container),
            feedFetcher: MockFeedFetcher(
                payloads: [
                    "https://example.com/feed.xml": Data(Self.rss.utf8),
                ]
            ),
            feedParser: XMLFeedParsing()
        )

        try await repository.addSubscription(url: "https://example.com/feed.xml")

        let subscriptions = try repository.fetchSubscriptions()
        let articles = try repository.fetchArticles(subscriptionID: nil)

        #expect(subscriptions.count == 1)
        #expect(subscriptions[0].title == "Repo Feed")
        #expect(articles.count == 1)
        #expect(articles[0].title == "Stored Article")
    }

    @Test
    func removeSubscriptionDeletesArticles() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataReaderRepository(
            modelContext: ModelContext(container),
            feedFetcher: MockFeedFetcher(
                payloads: [
                    "https://example.com/feed.xml": Data(Self.rss.utf8),
                ]
            ),
            feedParser: XMLFeedParsing()
        )

        try await repository.addSubscription(url: "https://example.com/feed.xml")
        let subscription = try #require(repository.fetchSubscriptions().first)

        try repository.removeSubscription(id: subscription.id)

        #expect(try repository.fetchSubscriptions().isEmpty)
        #expect(try repository.fetchArticles(subscriptionID: nil).isEmpty)
    }

    @Test
    func duplicateSubscriptionIsRejected() async throws {
        let container = try makeInMemoryContainer()
        let repository = SwiftDataReaderRepository(
            modelContext: ModelContext(container),
            feedFetcher: MockFeedFetcher(
                payloads: [
                    "https://example.com/feed.xml": Data(Self.rss.utf8),
                ]
            ),
            feedParser: XMLFeedParsing()
        )

        try await repository.addSubscription(url: "https://example.com/feed.xml")

        await #expect(throws: ReaderRepositoryError.duplicateSubscription) {
            try await repository.addSubscription(url: "https://example.com/feed.xml")
        }
    }

    private func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            SubscriptionRecord.self,
            ArticleRecord.self,
            AppSettingsRecord.self,
        ])

        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }

    private static let rss = """
    <rss version="2.0">
      <channel>
        <title>Repo Feed</title>
        <description>Desc</description>
        <item>
          <title>Stored Article</title>
          <link>https://example.com/articles/1</link>
          <description><![CDATA[<p>Summary</p>]]></description>
          <pubDate>Wed, 10 Jan 2024 10:00:00 +0000</pubDate>
        </item>
      </channel>
    </rss>
    """
}

private struct MockFeedFetcher: FeedFetching {
    let payloads: [String: Data]

    func fetchFeed(from url: URL) async throws -> Data {
        if let payload = payloads[url.absoluteString] {
            return payload
        }
        throw URLError(.fileDoesNotExist)
    }
}
