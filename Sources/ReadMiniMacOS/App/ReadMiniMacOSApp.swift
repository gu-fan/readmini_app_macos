import AppKit
import SwiftData
import SwiftUI

@main
struct ReadMiniMacOSApp: App {
    private let modelContainer: ModelContainer
    @StateObject private var store: ReaderStore

    init() {
        let schema = Schema([
            SubscriptionRecord.self,
            ArticleRecord.self,
            AppSettingsRecord.self,
        ])

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to create model container: \(error)")
        }

        let modelContext = ModelContext(modelContainer)
        let feedFetcher = URLSessionFeedFetching()
        let feedParser = XMLFeedParsing()
        let repository = SwiftDataReaderRepository(
            modelContext: modelContext,
            feedFetcher: feedFetcher,
            feedParser: feedParser
        )
        let settingsStore = SwiftDataSettingsStore(modelContext: modelContext)
        _store = StateObject(
            wrappedValue: ReaderStore(
                repository: repository,
                settingsStore: settingsStore
            )
        )

        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .modelContainer(modelContainer)
                .task {
                    await store.bootstrap()
                }
        }
        Settings {
            SettingsView()
                .environmentObject(store)
                .frame(width: 360)
                .padding(24)
        }
    }
}
