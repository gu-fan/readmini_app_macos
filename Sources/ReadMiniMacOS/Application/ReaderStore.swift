import Foundation
import SwiftUI

@MainActor
final class ReaderStore: ObservableObject {
    @Published private(set) var subscriptions: [Subscription] = []
    @Published private(set) var articles: [Article] = []
    @Published var selectedSubscriptionID: UUID?
    @Published var selectedArticleID: UUID?
    @Published private(set) var settings: UiSettings = .default
    @Published private(set) var isRefreshing = false
    @Published var isPresentingAddSheet = false
    @Published var isPresentingDefaultsSheet = false
    @Published var isPresentingSettingsSheet = false
    @Published var pendingURL = ""
    @Published var errorMessage: String?
    @Published var importMessage: String?

    private let repository: ReaderRepository
    private let settingsStore: SettingsStore

    init(repository: ReaderRepository, settingsStore: SettingsStore) {
        self.repository = repository
        self.settingsStore = settingsStore
    }

    func bootstrap() async {
        do {
            settings = try settingsStore.load()
            try reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reloadData() throws {
        subscriptions = try repository.fetchSubscriptions()
        articles = try repository.fetchArticles(subscriptionID: selectedSubscriptionID)

        if let selectedSubscriptionID, !subscriptions.contains(where: { $0.id == selectedSubscriptionID }) {
            self.selectedSubscriptionID = nil
            articles = try repository.fetchArticles(subscriptionID: nil)
        }

        if let selectedArticleID, !articles.contains(where: { $0.id == selectedArticleID }) {
            self.selectedArticleID = articles.first?.id
        } else if selectedArticleID == nil {
            self.selectedArticleID = articles.first?.id
        }
    }

    func addSubscription() async {
        defer { pendingURL = "" }
        do {
            try await repository.addSubscription(url: pendingURL)
            try reloadData()
            isPresentingAddSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeSubscription(id: UUID) {
        do {
            try repository.removeSubscription(id: id)
            try reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshAll() async {
        await runRefresh {
            try await self.repository.refreshAll()
        }
    }

    func refreshSelected() async {
        guard let selectedSubscriptionID else {
            await refreshAll()
            return
        }

        await runRefresh {
            try await self.repository.refreshSubscription(id: selectedSubscriptionID)
        }
    }

    func importDefaults(_ feeds: [DefaultFeedSource]) async {
        let results = await repository.importDefaultFeeds(feeds)
        do {
            try reloadData()
            let importedCount = results.filter(\.wasImported).count
            importMessage = importedCount == 0 ? "所选默认源已存在，无需重复导入。" : "已导入 \(importedCount) 个默认源。"
            isPresentingDefaultsSheet = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateThemeMode(_ mode: AppThemeMode) {
        do {
            try settingsStore.save(themeMode: mode)
            settings = try settingsStore.load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateFontSize(_ size: ReaderFontSize) {
        do {
            try settingsStore.save(fontSize: size)
            settings = try settingsStore.load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectSubscription(_ id: UUID?) {
        selectedSubscriptionID = id
        do {
            articles = try repository.fetchArticles(subscriptionID: id)
            selectedArticleID = articles.first?.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func article(for id: UUID?) -> Article? {
        guard let id else { return nil }
        return articles.first(where: { $0.id == id })
    }

    func dismissError() {
        errorMessage = nil
    }

    func dismissImportMessage() {
        importMessage = nil
    }

    private func runRefresh(_ operation: @escaping () async throws -> Void) async {
        isRefreshing = true
        defer { isRefreshing = false }

        do {
            try await operation()
            try reloadData()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
