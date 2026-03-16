import SwiftUI
import SwiftData
import OrderedCollections

enum BookmarkSort: String, CaseIterable {
    case dateAddedNewest = "Newest First"
    case dateAddedOldest = "Oldest First"
    case titleAZ = "Title A–Z"
    case titleZA = "Title Z–A"
}

fileprivate struct ReorderState: Hashable {
    var sort: BookmarkSort?
    var selectedTag: String?
}

struct BookmarkListView: View {
    @Environment(\.openURL) private var openURL
    @Binding var showSettings: Bool
    
    @State private var displayBookmarks: [Bookmark] = []
    @State private var bookmarks: OrderedDictionary<Int, Bookmark> = [:]
    @State private var searchText = ""
    @State private var sort: BookmarkSort = .dateAddedNewest
    @State private var selectedTag: String? = nil
    @State private var availableTags: [String] = []
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var showAdd = false
    @State private var editTarget: Bookmark? = nil
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(displayBookmarks) { bookmark in
                    Button {
                        openURL(bookmark.url)
                    } label: {
                        BookmarkRow(bookmark: bookmark) {
                            editTarget = bookmark
                        } toggleRead: {
                            Task {
                                await toggleUnreadStatus(to: !bookmark.unread, forBookmarkWithId: bookmark.bookmarkId)
                            }
                        } delete: {
                            Task {
                                await deleteBookmark(withId: bookmark.id)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
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
                toolbarItems
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
                AddEditBookmarkView(mode: .add) { newBookmark in
                    bookmarks[newBookmark.id] = newBookmark
                    sortAndFilter()
                }
            }
            .sheet(item: $editTarget) { bookmark in
                AddEditBookmarkView(mode: .edit(bookmark)) { updatedBookmark in
                    bookmarks[updatedBookmark.id] = updatedBookmark
                    sortAndFilter()
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
        .onChange(of: ReorderState(sort: sort, selectedTag: selectedTag)) {
            sortAndFilter()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem {
            Button { showAdd = true } label: {
                Label("Add Bookmark", systemImage: "plus")
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
                Label("Sort Bookmarks", systemImage: "arrow.up.arrow.down")
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
                    Label("Filter by tag", systemImage: selectedTag != nil ? "tag.fill" : "tag")
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
                Label("Settings", systemImage: "gear")
            }
        }
    }
    
    // MARK: - Data
    
    private func initialLoad() async {
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
            
            bookmarks = OrderedDictionary(response.results.map { ($0.bookmarkId, $0) }) { first, _ in first }
            availableTags = Array(Set(response.results.flatMap { $0.tagNames })).sorted()
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
        
        sortAndFilter()
    }
    
    private func toggleUnreadStatus(to unread: Bool, forBookmarkWithId id: Int) async {
        do {
            guard let api = KeychainHelper.makeAPI() else { return }
            let bm = try await api.updateBookmarkProperties(id: id, BookmarkPatchRequest(unread: unread))
            
            bookmarks[id] = bm
            sortAndFilter()
        } catch {
            assertionFailure("\(error)")
            self.error = error.localizedDescription
        }
    }
    
    private func deleteBookmark(withId id: Int) async {
        guard let api = KeychainHelper.makeAPI() else { return }
        
        do {
            try await api.deleteBookmark(id: id)
            bookmarks[id] = nil
            sortAndFilter()
        } catch {
            assertionFailure("\(error)")
            self.error = error.localizedDescription
        }
    }
    
    private func sortAndFilter() {
        var result = Array(bookmarks.values)
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
        
        displayBookmarks = result
    }
}

// MARK: - Bookmark Row

struct BookmarkRow: View {
    @Environment(\.openURL) private var openURL
    
    private let bookmark: Bookmark
    private let makeActive: () -> Void
    private let toggleRead: () -> Void
    private let delete: () -> Void
    
    init(bookmark: Bookmark, makeActive: @escaping () -> Void, toggleRead: @escaping () -> Void, delete: @escaping () -> Void) {
        self.bookmark = bookmark
        self.makeActive = makeActive
        self.toggleRead = toggleRead
        self.delete = delete
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(bookmark.displayTitle)
                .font(.headline)
                .lineLimit(2)
            Text(bookmark.url.absoluteString)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            if !bookmark.tagNames.isEmpty {
                TagChipRow(tags: bookmark.tagNames)
            }
        }
        .padding(.vertical, 4)
        .contextMenu(ContextMenu(menuItems: {
            Button {
                makeActive()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            
            Button {
                openURL(bookmark.url)
            } label: {
                Label("Open", systemImage: "envelope.open.fill")
            }
            
            Button(role: .destructive) {
                delete()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }))
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                toggleRead()
            } label: {
                Label("Mark " + (bookmark.unread ? "read" : "unread"), systemImage: bookmark.unread ? "book.closed.fill" : "book.fill")
            }
            
            Button {
                makeActive()
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                delete()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
    }
}

struct TagChipRow: View {
    let tags: [String]
    
    var body: some View {
        ScrollView(.horizontal) {
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
        .scrollIndicators(.hidden)
    }
}
