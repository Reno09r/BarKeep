import SwiftUI

struct BarPanelView: View {
    let items: [MenuBarItem]
    let imageProvider: (MenuBarItem) -> NSImage?
    let onActivate: (MenuBarItem) -> Void
    let onClose: () -> Void

    @State private var query = ""
    @FocusState private var searchFocused: Bool

    private var filteredItems: [MenuBarItem] {
        guard !query.isEmpty else { return items }
        return items.filter { $0.displayName.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    if filteredItems.isEmpty {
                        Text("Ничего не найдено")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                    } else {
                        ForEach(filteredItems) { item in
                            iconButton(for: item)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }

            Divider()
                .frame(height: 26)
                .opacity(0.4)

            searchField
                .padding(.trailing, 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
        .padding(1)
        .onAppear { searchFocused = true }
        .onExitCommand { onClose() }
    }

    private func iconButton(for item: MenuBarItem) -> some View {
        Button {
            onActivate(item)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.06))

                if let image = imageProvider(item) {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .padding(5)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 34, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(item.displayName)
    }

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            TextField("Поиск", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($searchFocused)
                .onSubmit {
                    if let first = filteredItems.first { onActivate(first) }
                }

            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .frame(width: 165, height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        )
    }
}
