import AppKit

@main
struct BarKeepApp {
    @MainActor
    static func main() {
        let arguments = CommandLine.arguments
        if arguments.contains("--scan") {
            runScan()
            return
        }
        if let index = arguments.firstIndex(of: "--send"), index + 1 < arguments.count {
            CommandBus.send(arguments[index + 1])
            print("Отправлено: \(arguments[index + 1])")
            return
        }
        if let index = arguments.firstIndex(of: "--press"), index + 1 < arguments.count {
            runPress(identifier: arguments[index + 1])
            return
        }

        let application = NSApplication.shared
        let delegate = AppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }

    @MainActor
    private static func runScan() {
        let scanner = MenuBarItemScanner()
        let items = scanner.scan()
        print("Найдено \(items.count) элементов (меню-бар \(ItemActivator.menuBarHeight) pt)")
        for item in items {
            print(String(
                format: "%@%-28@ x=%7.1f y=%6.1f w=%6.1f h=%5.1f ax=%@ pid=%6d %@",
                item.isOffscreen ? "◌ " : "  ",
                item.displayName as NSString,
                item.frame.minX, item.frame.minY, item.frame.width, item.frame.height,
                item.axElement == nil ? "—" : "✓",
                item.ownerPID,
                item.bundleIdentifier ?? "?"
            ))
        }
    }

    @MainActor
    private static func runPress(identifier: String) {
        let items = MenuBarItemScanner().scan()
        guard let item = items.first(where: {
            String($0.windowID) == identifier || $0.displayName.localizedCaseInsensitiveContains(identifier)
        }) else {
            print("Не найдено: \(identifier)")
            exit(1)
        }
        let ok = ItemActivator.activate(item)
        print("\(ok ? "OK" : "FAIL"): \(item.displayName) ax=\(item.axElement != nil)")
        exit(ok ? 0 : 1)
    }
}
