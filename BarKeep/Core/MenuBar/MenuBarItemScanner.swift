import AppKit

/// Находит иконки меню-бара: окна слоя 25 + соответствующие AX-элементы.
@MainActor
final class MenuBarItemScanner {
    private struct Candidate {
        let windowID: CGWindowID
        let pid: pid_t
        let ownerName: String
        let title: String?
        let frame: CGRect
        let isOnScreen: Bool
    }

    private struct AXEntry {
        let element: AXUIElement
        let frame: CGRect
        let title: String?
    }

    func scan() -> [MenuBarItem] {
        guard let raw = CGWindowListCopyWindowInfo(
            [.optionAll, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            Log.error("CGWindowListCopyWindowInfo вернул nil")
            return []
        }

        var candidates: [Candidate] = []

        for dict in raw {
            guard let layer = dict[kCGWindowLayer as String] as? Int, layer == 25 else { continue }
            guard let bounds = dict[kCGWindowBounds as String] as? NSDictionary,
                  let frame = CGRect(dictionaryRepresentation: bounds as CFDictionary) else { continue }

            // Иконка меню-бара: невысокая, прижата к верхней кромке.
            // При включённом автоскрытии macOS отдаёт y ≈ -37, поэтому допускаем отрицательные значения.
            guard frame.width >= 8, frame.width <= 1200 else { continue }
            guard frame.height >= 12, frame.height <= 60 else { continue }
            guard frame.maxY <= 60, frame.minY >= -120 else { continue }

            let windowID = (dict[kCGWindowNumber as String] as? NSNumber)?.uint32Value ?? 0
            guard windowID != 0 else { continue }

            let pid = (dict[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value ?? 0
            let ownerName = dict[kCGWindowOwnerName as String] as? String ?? "Неизвестно"
            let title = dict[kCGWindowName as String] as? String
            let isOnScreen = (dict[kCGWindowIsOnscreen as String] as? NSNumber)?.boolValue ?? false

            candidates.append(Candidate(
                windowID: windowID,
                pid: pid,
                ownerName: ownerName,
                title: title,
                frame: frame,
                isOnScreen: isOnScreen
            ))
        }

        var axCache: [pid_t: [AXEntry]] = [:]
        for pid in Set(candidates.map(\.pid)) where pid > 0 {
            axCache[pid] = accessiblityEntries(for: pid)
        }

        var result = candidates.map { candidate -> MenuBarItem in
            let entry = matchingEntry(for: candidate, in: axCache[candidate.pid] ?? [])
            let bundleIdentifier = NSRunningApplication(processIdentifier: candidate.pid)?.bundleIdentifier
            let title = (entry?.title?.isEmpty == false ? entry?.title : candidate.title)
            return MenuBarItem(
                windowID: candidate.windowID,
                ownerPID: candidate.pid,
                ownerName: candidate.ownerName,
                bundleIdentifier: bundleIdentifier,
                title: title,
                frame: candidate.frame,
                isOnScreen: candidate.isOnScreen,
                axElement: entry?.element
            )
        }

        result.sort { $0.frame.minX < $1.frame.minX }
        return disambiguate(result)
    }

    private func accessiblityEntries(for pid: pid_t) -> [AXEntry] {
        guard let bar = AX.extrasMenuBar(for: pid) else { return [] }
        return AX.children(bar).compactMap { child in
            guard let frame = AX.frame(child) else { return nil }
            let title = AX.string(child, kAXTitleAttribute)
            return AXEntry(element: child, frame: frame, title: title)
        }
    }

    private func matchingEntry(for candidate: Candidate, in entries: [AXEntry]) -> AXEntry? {
        entries.first { entry in
            abs(entry.frame.minX - candidate.frame.minX) < 4 &&
            abs(entry.frame.width - candidate.frame.width) < 10
        } ?? entries.first { entry in
            // Запасной вариант: совпадение по центру и примерной ширине.
            let centerDelta = abs(entry.frame.midX - candidate.frame.midX)
            let widthDelta = abs(entry.frame.width - candidate.frame.width)
            return centerDelta < 6 && widthDelta < 20
        }
    }

    /// Разные приложения могут отдавать одинаковые имена — добавляем индекс.
    private func disambiguate(_ items: [MenuBarItem]) -> [MenuBarItem] {
        var counts: [String: Int] = [:]
        for item in items { counts[item.displayName, default: 0] += 1 }
        guard counts.values.contains(where: { $0 > 1 }) else { return items }

        var seen: [String: Int] = [:]
        var result: [MenuBarItem] = []
        for item in items {
            let name = item.displayName
            guard counts[name, default: 0] > 1 else {
                result.append(item)
                continue
            }
            seen[name, default: 0] += 1
            let index = seen[name] ?? 1
            var copy = item
            copy.displaySuffix = " (\(index))"
            result.append(copy)
        }
        return result
    }
}
