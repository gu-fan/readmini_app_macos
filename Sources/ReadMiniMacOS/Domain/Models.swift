import Foundation

struct Subscription: Identifiable, Equatable, Hashable {
    let id: UUID
    let title: String
    let url: String
    let description: String
    let addedAt: Date
    let lastRefreshedAt: Date?
}

struct Article: Identifiable, Equatable, Hashable {
    let id: UUID
    let subscriptionID: UUID
    let feedTitle: String
    let title: String
    let link: String
    let firstImageURL: String?
    let summaryHTML: String
    let contentHTML: String
    let summaryText: String
    let contentText: String
    let author: String
    let publishedAt: Date?
}

struct DefaultFeedSource: Identifiable, Hashable {
    var id: String { url }
    let title: String
    let url: String
    let note: String
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system:
            return "跟随系统"
        case .light:
            return "亮色"
        case .dark:
            return "暗色"
        }
    }
}

enum ReaderFontSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var label: String {
        switch self {
        case .small:
            return "小"
        case .medium:
            return "中"
        case .large:
            return "大"
        }
    }

    var bodyPointSize: Double {
        switch self {
        case .small:
            return 15
        case .medium:
            return 17
        case .large:
            return 19
        }
    }

    var titlePointSize: Double {
        bodyPointSize + 10
    }
}

struct UiSettings: Equatable {
    let themeMode: AppThemeMode
    let fontSize: ReaderFontSize

    static let `default` = UiSettings(themeMode: .system, fontSize: .medium)
}

struct FeedPayload: Equatable {
    let title: String
    let description: String
    let entries: [FeedEntry]
}

struct FeedEntry: Equatable {
    let title: String
    let link: String
    let summaryHTML: String
    let contentHTML: String
    let author: String
    let publishedAt: Date?
    let firstImageURL: String?
}

enum ReaderRepositoryError: LocalizedError, Equatable {
    case invalidURL
    case duplicateSubscription
    case invalidFeed
    case emptyFeed

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "请输入有效的 RSS 或 Atom 地址。"
        case .duplicateSubscription:
            return "该订阅已存在。"
        case .invalidFeed:
            return "订阅内容不是可识别的 RSS/Atom。"
        case .emptyFeed:
            return "订阅为空，暂时没有可展示的文章。"
        }
    }
}

protocol FeedFetching: Sendable {
    func fetchFeed(from url: URL) async throws -> Data
}

protocol FeedParsing: Sendable {
    func parse(data: Data) throws -> FeedPayload
}

@MainActor
protocol ReaderRepository {
    func fetchSubscriptions() throws -> [Subscription]
    func fetchArticles(subscriptionID: UUID?) throws -> [Article]
    func addSubscription(url: String) async throws
    func removeSubscription(id: UUID) throws
    func refreshAll() async throws
    func refreshSubscription(id: UUID) async throws
    func importDefaultFeeds(_ feeds: [DefaultFeedSource]) async -> [ImportResult]
}

@MainActor
protocol SettingsStore {
    func load() throws -> UiSettings
    func save(themeMode: AppThemeMode) throws
    func save(fontSize: ReaderFontSize) throws
}

struct ImportResult: Equatable {
    let feed: DefaultFeedSource
    let wasImported: Bool
    let error: String?
}
