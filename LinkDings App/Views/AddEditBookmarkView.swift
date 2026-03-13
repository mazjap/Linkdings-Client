import SwiftUI

struct AddEditBookmarkView: View {
    enum Mode {
        case add
        case edit(Bookmark)
    }

    let mode: Mode
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var url = ""
    @State private var title = ""
    @State private var description = ""
    @State private var notes = ""
    @State private var tagInput = ""
    @State private var tagNames: [String] = []
    @State private var isArchived = false
    @State private var unread = false
    @State private var shared = false
    @State private var isSaving = false
    @State private var error: String? = nil

    private var navigationTitle: String {
        switch mode {
        case .add: "Add Bookmark"
        case .edit: "Edit Bookmark"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("URL") {
                    TextField("https://...", text: $url)
                        .urlTextFieldStyle()
                }

                Section("Details") {
                    TextField("Title (optional)", text: $title)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...)
                }

                Section {
                    HStack {
                        TextField("Add tag", text: $tagInput)
                            .noAutocapitalization()
                            .onSubmit { addTag() }
                        Button("Add", action: addTag)
                            .disabled(tagInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    if !tagNames.isEmpty {
                        TagPillGrid(tags: tagNames) { tag in
                            tagNames.removeAll { $0 == tag }
                        }
                    }
                } header: {
                    Text("Tags")
                }

                Section("Options") {
                    Toggle("Mark as Unread", isOn: $unread)
                    Toggle("Archived", isOn: $isArchived)
                    Toggle("Shared", isOn: $shared)
                }

                if let error {
                    Section {
                        Text(error).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await save() } }
                        .disabled(url.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onAppear { populateFields() }
        }
    }

    private func populateFields() {
        guard case .edit(let bookmark) = mode else { return }
        url = bookmark.url
        title = bookmark.title
        description = bookmark.description
        notes = bookmark.notes
        tagNames = bookmark.tagNames
        isArchived = bookmark.isArchived
        unread = bookmark.unread
        shared = bookmark.shared
    }

    private func addTag() {
        let tag = tagInput.trimmingCharacters(in: .whitespaces)
        guard !tag.isEmpty, !tagNames.contains(tag) else { return }
        tagNames.append(tag)
        tagInput = ""
    }

    private func save() async {
        guard let api = KeychainHelper.makeAPI() else { return }
        isSaving = true
        error = nil
        let body = BookmarkRequest(
            url: url.trimmingCharacters(in: .whitespacesAndNewlines),
            title: title,
            description: description,
            notes: notes,
            isArchived: isArchived,
            unread: unread,
            shared: shared,
            tagNames: tagNames
        )
        do {
            switch mode {
            case .add:
                _ = try await api.createBookmark(body)
            case .edit(let bookmark):
                _ = try await api.updateBookmark(id: bookmark.id, body)
            }
            onSave()
            dismiss()
        } catch {
            self.error = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Tag Pill Grid

struct TagPillGrid: View {
    let tags: [String]
    let onRemove: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), alignment: .leading)], alignment: .leading, spacing: 6) {
            ForEach(tags, id: \.self) { tag in
                HStack(spacing: 3) {
                    Text(tag).font(.caption)
                    Button {
                        onRemove(tag)
                    } label: {
                        Label("Remove tag", systemImage: "xmark")
                            .font(.caption2)
                            .labelStyle(.iconOnly)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .padding(.vertical, 2)
    }
}
