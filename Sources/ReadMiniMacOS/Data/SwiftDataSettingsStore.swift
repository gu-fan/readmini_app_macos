import Foundation
import SwiftData

@MainActor
final class SwiftDataSettingsStore: SettingsStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func load() throws -> UiSettings {
        let record = try fetchOrCreateRecord()
        let themeMode = AppThemeMode(rawValue: record.themeModeRawValue) ?? .system
        let fontSize = ReaderFontSize(rawValue: record.fontSizeRawValue) ?? .medium
        return UiSettings(themeMode: themeMode, fontSize: fontSize)
    }

    func save(themeMode: AppThemeMode) throws {
        let record = try fetchOrCreateRecord()
        record.themeModeRawValue = themeMode.rawValue
        try modelContext.save()
    }

    func save(fontSize: ReaderFontSize) throws {
        let record = try fetchOrCreateRecord()
        record.fontSizeRawValue = fontSize.rawValue
        try modelContext.save()
    }

    private func fetchOrCreateRecord() throws -> AppSettingsRecord {
        let descriptor = FetchDescriptor<AppSettingsRecord>()
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }

        let record = AppSettingsRecord()
        modelContext.insert(record)
        try modelContext.save()
        return record
    }
}
