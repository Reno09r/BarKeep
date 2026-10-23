import SwiftUI

@MainActor
struct BarPanelView: View {
    let items: [MenuBarItem]
    let imageProvider: (MenuBarItem) -> NSImage?
    let onActivate: (MenuBarItem) -> Void
    let onHideApp: (MenuBarItem) -> Void
    let onQuitApp: (_ item: MenuBarItem, _ force: Bool) -> Void
    let onClose: () -> Void

    @ObservedObject private var localization = Localization.shared
    @State private var query = ""
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
                ForEach(filteredItems) { item in
                    iconButton(for: item)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .fixedSize(horizontal: true, vertical: false)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Ширина ряда: 34 pt иконка + 3 pt отступ + 16 pt поля.
    private var rowWidth: CGFloat {
        filteredItems.isEmpty ? 150 : CGFloat(filteredItems.count) * 37 + 13
    }

    private func iconButton(for item: MenuBarItem) -> some View {
        let canManage = AppTerminator.canManage(item: item)
        let appName = AppTerminator.displayName(for: item)

        return Button {
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

    private var filteredItems: [MenuBarItem] {
        let tokens = Self.normalized(query)
            .split(separator: " ")
            .map(String.init)
            .filter { !$0.isEmpty }
        guard !tokens.isEmpty else { return items }

        return items.filter { item in
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

    private static func searchText(for item: MenuBarItem) -> String {
        [
            item.displayName,
            item.ownerName,
            item.title ?? "",
            item.bundleIdentifier ?? "",
        ]
        .joined(separator: " ")
        .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    private static func normalized(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// Простая транслитерация, чтобы «телеграм» находил Telegram, а «telegram» — Телеграм.
    private static func transliterate(_ value: String) -> String {
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
