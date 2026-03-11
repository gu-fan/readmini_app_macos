import Foundation
import SwiftData

@Model
final class SubscriptionRecord {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var url: String
    var title: String
    var feedDescription: String
    var addedAt: Date
    var lastRefreshedAt: Date?

    init(
        id: UUID = UUID(),
        url: String,
        title: String,
        feedDescription: String,
        addedAt: Date = .now,
        lastRefreshedAt: Date? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.feedDescription = feedDescription
        self.addedAt = addedAt
        self.lastRefreshedAt = lastRefreshedAt
    }
}

@Model
final class ArticleRecord {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var stableKey: String
    var subscriptionID: UUID
    var feedTitle: String
    var title: String
    var link: String
    var firstImageURL: String?
    var summaryHTML: String
    var contentHTML: String
    var author: String
    var publishedAt: Date?

    init(
        id: UUID = UUID(),
        stableKey: String,
        subscriptionID: UUID,
        feedTitle: String,
        title: String,
        link: String,
        firstImageURL: String?,
        summaryHTML: String,
        contentHTML: String,
        author: String,
        publishedAt: Date?
    ) {
        self.id = id
        self.stableKey = stableKey
        self.subscriptionID = subscriptionID
        self.feedTitle = feedTitle
        self.title = title
        self.link = link
        self.firstImageURL = firstImageURL
        self.summaryHTML = summaryHTML
        self.contentHTML = contentHTML
        self.author = author
        self.publishedAt = publishedAt
    }
}

@Model
final class AppSettingsRecord {
    @Attribute(.unique) var key: String
    var themeModeRawValue: String
    var fontSizeRawValue: String

    init(
        key: String = "app-settings",
        themeModeRawValue: String = AppThemeMode.system.rawValue,
        fontSizeRawValue: String = ReaderFontSize.medium.rawValue
    ) {
        self.key = key
        self.themeModeRawValue = themeModeRawValue
        self.fontSizeRawValue = fontSizeRawValue
    }
}
