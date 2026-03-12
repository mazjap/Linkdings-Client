import SwiftUI
import SwiftData

enum BookmarkSort: String, CaseIterable {
    case dateAddedNewest = "Newest First"
    case dateAddedOldest = "Oldest First"
    case titleAZ = "Title A–Z"
    case titleZA = "Title Z–A"
}

struct BookmarkListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var cachedBookmarks: [CachedBookmark]
    @Binding var showSettings: Bool

    @State private var bookmarks: [Bookmark] = []
    @State private var searchText = ""
    @State private var sort: BookmarkSort = .dateAddedNewest
    @State private var selectedTag: String? = nil
    @State private var availableTags: [String] = []
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var showAdd = false
    @State private var editTarget: Bookmark? = nil

    private var displayBookmarks: [Bookmark] {
        var result = bookmarks
        if let tag = selectedTag {
            result = result.filter { $0.tagNames.contains(tag) }
        }
        switch sort {
        case .dateAddedNewest: result.sort { $0.dateAdded > $1.dateAdded }
        case .dateAddedOldest: result.sort { $0.dateAdded < $1.dateAdded }
        case .titleAZ:
            result.sort { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedAscending }
        case .titleZA:
            result.sort { $0.displayTitle.localizedCaseInsensitiveCompare($1.displayTitle) == .orderedDescending }
        }
        return result
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(displayBookmarks) { bookmark in
                    BookmarkRow(bookmark: bookmark)
                        .contentShape(Rectangle())
                        .onTapGesture { editTarget = bookmark }
                }
                .onDelete { indexSet in
                    Task { await deleteBookmarks(at: indexSet) }
                }
            }
            .searchable(text: $searchText, prompt: "Search bookmarks")
            .onSubmit(of: .search) {
                Task { await fetchBookmarks() }
            }
            .onChange(of: searchText) { _, new in
                if new.isEmpty { Task { await fetchBookmarks() } }
            }
            .navigationTitle("Bookmarks")
            .toolbar {
                ToolbarItem {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(BookmarkSort.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
                if !availableTags.isEmpty {
                    ToolbarItem {
                        Menu {
                            Button("All Tags") { selectedTag = nil }
                            Divider()
                            ForEach(availableTags, id: \.self) { tag in
                                Button {
                                    selectedTag = tag
                                } label: {
                                    if tag == selectedTag {
                                        Label(tag, systemImage: "checkmark")
                                    } else {
                                        Text(tag)
                                    }
                                }
                            }
                        } label: {
                            Image(systemName: selectedTag != nil ? "tag.fill" : "tag")
                        }
                    }
                }
                
                #if DEBUG
                ToolbarItem {
                    Button { KeychainHelper.clear() } label: {
                        Image(systemName: "eraser.fill")
                    }
                }
                #endif
                
                ToolbarItem {
                    Button { showSettings = true } label: {
                        Image(systemName: "gear")
                    }
                }
            }
            .overlay {
                if isLoading && bookmarks.isEmpty {
                    ProgressView()
                }
                if let error, bookmarks.isEmpty {
                    ContentUnavailableView(
                        "Couldn't Load Bookmarks",
                        systemImage: "exclamationmark.triangle",
                        description: Text(error)
                    )
                }
            }
            .refreshable { await fetchBookmarks() }
            .task { await initialLoad() }
            .sheet(isPresented: $showAdd) {
                AddEditBookmarkView(mode: .add) {
                    Task { await fetchBookmarks() }
                }
            }
            .sheet(item: $editTarget) { bookmark in
                AddEditBookmarkView(mode: .edit(bookmark)) {
                    Task { await fetchBookmarks() }
                }
            }
        }
        .onChange(of: showSettings) {
            if !showSettings {
                Task {
                    await fetchBookmarks()
                }
            }
        }
    }

    // MARK: - Data

    private func initialLoad() async {
        // Show cache immediately while API loads
        if bookmarks.isEmpty && !cachedBookmarks.isEmpty {
            bookmarks = cachedBookmarks.map { Bookmark(cache: $0) }
        }
        await fetchBookmarks()
    }

    private func fetchBookmarks() async {
        guard let api = KeychainHelper.makeAPI() else { return }
        isLoading = true
        error = nil
        do {
            let response = try await api.fetchBookmarks(
                query: searchText.isEmpty ? nil : searchText,
                limit: 200
            )
            bookmarks = response.results
            availableTags = Array(Set(response.results.flatMap { $0.tagNames })).sorted()
            // Only do full cache sync on unfiltered fetch
            if searchText.isEmpty {
                syncCache(with: response.results)
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    private func syncCache(with fetched: [Bookmark]) {
        let existingByID = Dictionary(uniqueKeysWithValues: cachedBookmarks.map { ($0.id, $0) })
        let fetchedIDs = Set(fetched.map { $0.id })
        for cached in cachedBookmarks where !fetchedIDs.contains(cached.id) {
            modelContext.delete(cached)
        }
        for bookmark in fetched {
            if let existing = existingByID[bookmark.id] {
                existing.update(from: bookmark)
            } else {
                modelContext.insert(CachedBookmark(from: bookmark))
            }
        }
    }

    private func deleteBookmarks(at indexSet: IndexSet) async {
        guard let api = KeychainHelper.makeAPI() else { return }
        let toDelete = indexSet.map { displayBookmarks[$0] }
        for bookmark in toDelete {
            do {
                try await api.deleteBookmark(id: bookmark.id)
                bookmarks.removeAll { $0.id == bookmark.id }
                if let cached = cachedBookmarks.first(where: { $0.id == bookmark.id }) {
                    modelContext.delete(cached)
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - Bookmark Row

struct BookmarkRow: View {
    let bookmark: Bookmark

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bookmark.displayTitle)
                .font(.headline)
                .lineLimit(2)
            Text(bookmark.url)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if !bookmark.tagNames.isEmpty {
                TagChipRow(tags: bookmark.tagNames)
            }
        }
        .padding(.vertical, 4)
    }
}

struct TagChipRow: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
    }
}

// MARK: - Cache → DTO bridge (for initial offline display)

extension Bookmark {
    init(cache: CachedBookmark) {
        self.init(
            id: cache.id,
            url: cache.url,
            title: cache.title,
            description: cache.bookmarkDescription,
            notes: cache.notes,
            websiteTitle: cache.websiteTitle,
            websiteDescription: nil,
            isArchived: cache.isArchived,
            unread: cache.unread,
            shared: cache.shared,
            tagNames: cache.tagNames,
            dateAdded: cache.dateAdded,
            dateModified: cache.dateModified
        )
    }
}
