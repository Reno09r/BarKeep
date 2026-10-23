import SwiftUI

@MainActor
struct BarPanelView: View {
    let items: [MenuBarItem]
    var sectionProvider: ((MenuBarItem) -> MenuBarLayoutController.Section)? = nil
    let imageProvider: (MenuBarItem) -> NSImage?
    let onActivate: (MenuBarItem) -> Void
    let onHideApp: (MenuBarItem) -> Void
    let onQuitApp: (_ item: MenuBarItem, _ force: Bool) -> Void
    let onClose: () -> Void

    @ObservedObject private var localization = Localization.shared
    @State private var query = ""
    @State private var selectedIndex: Int = 0
    @State private var filterAlwaysHidden = false
    @FocusState private var searchFocused: Bool

    var body: some View {
        HStack(spacing: 8) {
            HorizontalIconScrollView(contentWidth: rowWidth) {
                iconRow
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(height: 44)

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
        .onAppear {
            // Панель становится key уже после появления окна.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                searchFocused = true
            }
        }
        .onExitCommand { onClose() }
        .onKeyPress(.leftArrow) {
            guard !filteredItems.isEmpty else { return .ignored }
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard !filteredItems.isEmpty else { return .ignored }
            selectedIndex = min(filteredItems.count - 1, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.return) {
            guard selectedIndex >= 0 && selectedIndex < filteredItems.count else { return .ignored }
            onActivate(filteredItems[selectedIndex])
            return .handled
        }
    }

    // MARK: - Иконки

    private var iconRow: some View {
        HStack(spacing: 3) {
            if filteredItems.isEmpty {
                Text(Localization.tr(.noItemsFound))
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
            } else {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    iconButton(for: item, isSelected: index == selectedIndex)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func itemWidth(for item: MenuBarItem) -> CGFloat {
        let h = max(1, item.frame.height)
        let w = item.frame.width
        if w > h * 1.2 {
            return max(34, min(140, 24 * (w / h) + 10))
        }
        return 34
    }

    /// Динамическая ширина ряда с учётом пропорций элементов.
    private var rowWidth: CGFloat {
        if filteredItems.isEmpty { return 150 }
        let totalItemsWidth = filteredItems.reduce(0) { $0 + itemWidth(for: $1) }
        return totalItemsWidth + CGFloat(filteredItems.count - 1) * 3 + 16
    }

    private func iconButton(for item: MenuBarItem, isSelected: Bool) -> some View {
        let canManage = AppTerminator.canManage(item: item)
        let appName = AppTerminator.displayName(for: item)
        let width = itemWidth(for: item)

        return Button {
            onActivate(item)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                    )

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
            .frame(width: width, height: 34)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(item.displayName)
        .contextMenu {
            Button(Localization.tr(.activate)) {
                onActivate(item)
            }

            Button(Localization.tr(.hideAppName, appName)) {
                onHideApp(item)
            }
            .disabled(!canManage)

            Divider()

            Button(Localization.tr(.quitAppName, appName)) {
                onQuitApp(item, false)
            }
            .disabled(!canManage)

            Button(Localization.tr(.forceQuitAppName, appName)) {
                onQuitApp(item, true)
            }
            .disabled(!canManage)
        }
    }

    // MARK: - Поиск

    private var searchField: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

            TextField(Localization.tr(.searchPlaceholder), text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($searchFocused)
                .onChange(of: query) { _, _ in
                    selectedIndex = 0
                }
                .onSubmit {
                    if selectedIndex >= 0 && selectedIndex < filteredItems.count {
                        onActivate(filteredItems[selectedIndex])
                    } else if let first = filteredItems.first {
                        onActivate(first)
                    }
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

            if hasAlwaysHiddenItems {
                Button {
                    filterAlwaysHidden.toggle()
                    selectedIndex = 0
                } label: {
                    Image(systemName: filterAlwaysHidden ? "eye.slash.fill" : "eye.slash")
                        .font(.system(size: 12))
                        .foregroundStyle(filterAlwaysHidden ? Color.accentColor : Color.secondary)
                }
                .buttonStyle(.plain)
                .help(Localization.tr(.sectionAlwaysHidden))
            }
        }
        .padding(.horizontal, 9)
        .frame(width: 165, height: 30)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.07))
        )
    }

    private var hasAlwaysHiddenItems: Bool {
        guard let sectionProvider else { return false }
        return items.contains { sectionProvider($0) == .alwaysHidden }
    }

    private var baseItems: [MenuBarItem] {
        guard let sectionProvider, hasAlwaysHiddenItems else { return items }
        if filterAlwaysHidden {
            return items.filter { sectionProvider($0) == .alwaysHidden }
        } else {
            return items.filter { sectionProvider($0) != .alwaysHidden }
        }
    }

    private var filteredItems: [MenuBarItem] {
        let base = baseItems
        let tokens = Self.normalized(query)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return base }

        return base.filter { item in
            let haystack = Self.searchText(for: item)
            let transliterated = Self.transliterate(haystack)
            return tokens.allSatisfy { token in
                let variants = [token, Self.transliterate(token)]
                return variants.contains { variant in
                    !variant.isEmpty && (haystack.contains(variant) || transliterated.contains(variant))
                }
            }
        }
    }

    static func searchText(for item: MenuBarItem) -> String {
        [
            item.displayName,
            item.ownerName,
            item.title ?? "",
            item.bundleIdentifier ?? "",
        ]
        .joined(separator: " ")
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// Простая транслитерация, чтобы «телеграм» находил Telegram, а «telegram» — Телеграм.
    static func transliterate(_ value: String) -> String {
        var result = ""
        result.reserveCapacity(value.count)
        for character in value {
            switch character {
            case "а", "ә": result += "a"
            case "б": result += "b"
            case "в": result += "v"
            case "г", "ғ": result += "g"
            case "д": result += "d"
            case "е", "ё", "э": result += "e"
            case "ж": result += "zh"
            case "з": result += "z"
            case "и", "й", "і": result += "i"
            case "к", "қ": result += "k"
            case "л": result += "l"
            case "м": result += "m"
            case "н", "ң": result += "n"
            case "о", "ө": result += "o"
            case "п": result += "p"
            case "р": result += "r"
            case "с": result += "s"
            case "т": result += "t"
            case "у", "ұ", "ү": result += "u"
            case "ф": result += "f"
            case "х", "һ": result += "h"
            case "ц": result += "ts"
            case "ч": result += "ch"
            case "ш": result += "sh"
            case "щ": result += "sch"
            case "ъ", "ь": result += ""
            case "ы": result += "y"
            case "ю": result += "yu"
            case "я": result += "ya"
            default: result.append(character)
            }
        }
        return result
    }
}
