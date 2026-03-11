import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: ReaderStore

    var body: some View {
        NavigationSplitView {
            SubscriptionSidebar()
        } content: {
            ArticleListPane()
        } detail: {
            ArticleDetailPane(article: store.article(for: store.selectedArticleID))
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(store.settings.themeMode.preferredColorScheme)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        store.isPresentingSettingsSheet = true
                    } label: {
                        Label("设置", systemImage: "gearshape")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $store.isPresentingAddSheet) {
            AddSubscriptionSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.isPresentingDefaultsSheet) {
            DefaultFeedsSheet()
                .environmentObject(store)
        }
        .sheet(isPresented: $store.isPresentingSettingsSheet) {
            SettingsSheet()
                .environmentObject(store)
        }
        .alert("提示", isPresented: errorPresented) {
            Button("好的", role: .cancel) {
                store.dismissError()
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
        .alert("默认源导入完成", isPresented: importMessagePresented) {
            Button("知道了", role: .cancel) {
                store.dismissImportMessage()
            }
        } message: {
            Text(store.importMessage ?? "")
        }
    }

    private var errorPresented: Binding<Bool> {
        Binding(
            get: { store.errorMessage != nil },
            set: { newValue in
                if !newValue {
                    store.dismissError()
                }
            }
        )
    }

    private var importMessagePresented: Binding<Bool> {
        Binding(
            get: { store.importMessage != nil },
            set: { newValue in
                if !newValue {
                    store.dismissImportMessage()
                }
            }
        )
    }
}

private struct SubscriptionSidebar: View {
    @EnvironmentObject private var store: ReaderStore

    var body: some View {
        List(selection: $store.selectedSubscriptionID) {
            Section("阅读空间") {
                Button {
                    store.selectSubscription(nil)
                } label: {
                    Label("全部文章", systemImage: "square.stack.3d.up")
                }
                .buttonStyle(.plain)
            }

            Section("订阅") {
                ForEach(store.subscriptions) { subscription in
                    SubscriptionRow(subscription: subscription)
                        .tag(Optional(subscription.id))
                        .contextMenu {
                            Button("刷新") {
                                store.selectSubscription(subscription.id)
                                Task { await store.refreshSelected() }
                            }
                            Button("删除", role: .destructive) {
                                store.removeSubscription(id: subscription.id)
                            }
                        }
                        .onTapGesture {
                            store.selectSubscription(subscription.id)
                        }
                }
            }
        }
        .navigationTitle("ReadMini")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.isPresentingAddSheet = true
                } label: {
                    Label("添加订阅", systemImage: "plus")
                }

                Button {
                    store.isPresentingDefaultsSheet = true
                } label: {
                    Label("默认源", systemImage: "square.grid.2x2")
                }

                Button {
                    Task { await store.refreshSelected() }
                } label: {
                    if store.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("刷新", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(store.isRefreshing)
            }
        }
    }
}

private struct SubscriptionRow: View {
    let subscription: Subscription

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(subscription.title)
                .font(.headline)
                .lineLimit(2)
            if !subscription.description.isEmpty {
                Text(subscription.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ArticleListPane: View {
    @EnvironmentObject private var store: ReaderStore

    var body: some View {
        List(selection: $store.selectedArticleID) {
            ForEach(store.articles) { article in
                ArticleListRow(article: article)
                    .tag(Optional(article.id))
                    .onTapGesture {
                        store.selectedArticleID = article.id
                    }
            }
        }
        .navigationTitle(store.selectedSubscriptionID == nil ? "全部文章" : currentSubscriptionTitle)
        .overlay {
            if store.articles.isEmpty {
                ContentUnavailableView(
                    "还没有文章",
                    systemImage: "newspaper",
                    description: Text("先添加一个 RSS/Atom 订阅，或导入默认源。")
                )
            }
        }
    }

    private var currentSubscriptionTitle: String {
        store.subscriptions.first(where: { $0.id == store.selectedSubscriptionID })?.title ?? "文章"
    }
}

private struct ArticleListRow: View {
    let article: Article

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            if let firstImageURL = article.firstImageURL, let url = URL(string: firstImageURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.quaternary)
                }
                .frame(width: 88, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.headline)
                    .lineLimit(3)
                Text(article.feedTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(article.summaryText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
                if let publishedText {
                    Text(publishedText)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var publishedText: String? {
        guard let publishedAt = article.publishedAt else {
            return nil
        }

        return publishedAt.formatted(date: .abbreviated, time: .shortened)
    }
}

struct ArticleDetailPane: View {
    @EnvironmentObject private var store: ReaderStore
    let article: Article?
    @State private var renderedContent = AttributedString("")

    var body: some View {
        Group {
            if let article {
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let firstImageURL = article.firstImageURL, let url = URL(string: firstImageURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(.quaternary)
                                    .frame(height: 220)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 220)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }

                        Text(article.title)
                            .font(.system(size: store.settings.fontSize.titlePointSize, weight: .bold))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(article.feedTitle)
                                .font(.headline)
                                .foregroundStyle(.secondary)

                            if !article.author.isEmpty {
                                Text(article.author)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let publishedAt = article.publishedAt {
                                Text(publishedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }

                        Text(currentRenderedContent)
                            .font(.system(size: store.settings.fontSize.bodyPointSize))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack {
                            if let url = URL(string: article.link), !article.link.isEmpty {
                                Link(destination: url) {
                                    Label("在浏览器打开", systemImage: "safari")
                                }
                            }

                            Button {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(article.link, forType: .string)
                            } label: {
                                Label("复制链接", systemImage: "link")
                            }
                            .disabled(article.link.isEmpty)
                        }
                        .padding(.top, 8)
                    }
                    .padding(28)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ContentUnavailableView(
                    "选择一篇文章",
                    systemImage: "doc.text",
                    description: Text("左侧选择订阅，中间选择文章后即可开始阅读。")
                )
            }
        }
        .navigationTitle(article?.feedTitle ?? "阅读")
        .task(id: renderCacheKey) {
            renderedContent = buildRenderedContent()
        }
    }

    private var renderCacheKey: String {
        "\(article?.id.uuidString ?? "empty")|\(store.settings.fontSize.rawValue)"
    }

    private var currentRenderedContent: AttributedString {
        renderedContent.characters.isEmpty ? buildRenderedContent() : renderedContent
    }

    private func buildRenderedContent() -> AttributedString {
        guard let article else {
            return AttributedString("")
        }

        if article.contentHTML.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return AttributedString(article.contentText)
        }

        return HTMLSupport.htmlToAttributedString(
            article.contentHTML,
            baseFontSize: store.settings.fontSize.bodyPointSize
        )
    }
}

private struct AddSubscriptionSheet: View {
    @EnvironmentObject private var store: ReaderStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("添加订阅")
                .font(.title2.bold())

            TextField("https://example.com/feed.xml", text: $store.pendingURL)
                .textFieldStyle(.roundedBorder)

            Text("支持 RSS 2.0 和 Atom 链接。")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("取消") {
                    store.pendingURL = ""
                    dismiss()
                }
                Button("添加") {
                    Task { await store.addSubscription() }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(store.pendingURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}

private struct DefaultFeedsSheet: View {
    @EnvironmentObject private var store: ReaderStore
    @State private var selectedFeedIDs = Set(defaultFeedCatalog.map(\.id))
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("导入默认源")
                    .font(.title2.bold())
                Spacer()
                Button("关闭") {
                    dismiss()
                }
            }

            HStack {
                Button("全选") {
                    selectedFeedIDs = Set(defaultFeedCatalog.map(\.id))
                }
                Button("清空") {
                    selectedFeedIDs.removeAll()
                }

                Spacer()

                Text("已选 \(selectedFeedIDs.count) 项")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            List(defaultFeedCatalog, id: \.id) { feed in
                Button {
                    toggleSelection(for: feed)
                } label: {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: selectedFeedIDs.contains(feed.id) ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(selectedFeedIDs.contains(feed.id) ? Color.accentColor : Color.secondary)
                            .padding(.top, 2)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(feed.title)
                                .font(.headline)
                            Text(feed.note)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(feed.url)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .frame(minHeight: 280)

            HStack {
                Spacer()
                Button("导入选中") {
                    let selectedFeeds = defaultFeedCatalog.filter { selectedFeedIDs.contains($0.id) }
                    Task { await store.importDefaults(selectedFeeds) }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedFeedIDs.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 560, height: 460)
    }

    private func toggleSelection(for feed: DefaultFeedSource) {
        if selectedFeedIDs.contains(feed.id) {
            selectedFeedIDs.remove(feed.id)
        } else {
            selectedFeedIDs.insert(feed.id)
        }
    }
}

private struct SettingsSheet: View {
    @EnvironmentObject private var store: ReaderStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("设置")
                    .font(.title2.bold())
                Spacer()
                Button("关闭") {
                    dismiss()
                }
            }

            SettingsView()
                .environmentObject(store)
        }
        .padding(24)
        .frame(width: 420)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var store: ReaderStore

    var body: some View {
        Form {
            Picker("主题", selection: themeBinding) {
                ForEach(AppThemeMode.allCases) { theme in
                    Text(theme.label).tag(theme)
                }
            }

            Picker("字体大小", selection: fontSizeBinding) {
                ForEach(ReaderFontSize.allCases) { size in
                    Text(size.label).tag(size)
                }
            }

            Text("ReadMini macOS v1")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .formStyle(.grouped)
    }

    private var themeBinding: Binding<AppThemeMode> {
        Binding(
            get: { store.settings.themeMode },
            set: { store.updateThemeMode($0) }
        )
    }

    private var fontSizeBinding: Binding<ReaderFontSize> {
        Binding(
            get: { store.settings.fontSize },
            set: { store.updateFontSize($0) }
        )
    }
}

private extension AppThemeMode {
    var preferredColorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
