import ApplicationServices

/// Тонкая обёртка над Accessibility API.
enum AX {
    static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    static func string(_ element: AXUIElement, _ name: String) -> String? {
        attribute(element, name) as? String
    }

    static func children(_ element: AXUIElement) -> [AXUIElement] {
        guard let value = attribute(element, kAXChildrenAttribute) else { return [] }
        return value as? [AXUIElement] ?? []
    }

    static func element(_ element: AXUIElement, _ name: String) -> AXUIElement? {
        guard let value = attribute(element, name), CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return (value as! AXUIElement)
    }

    static func point(_ element: AXUIElement, _ name: String) -> CGPoint? {
        guard let value = attribute(element, name), CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }
        var point = CGPoint.zero
        guard AXValueGetValue(value as! AXValue, .cgPoint, &point) else { return nil }
        return point
    }

    static func size(_ element: AXUIElement, _ name: String) -> CGSize? {
        guard let value = attribute(element, name), CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }
        var size = CGSize.zero
        guard AXValueGetValue(value as! AXValue, .cgSize, &size) else { return nil }
        return size
    }

    static func frame(_ element: AXUIElement) -> CGRect? {
        guard let position = point(element, kAXPositionAttribute),
              let size = size(element, kAXSizeAttribute) else {
            return nil
        }
        return CGRect(origin: position, size: size)
    }

    static func extrasMenuBar(for pid: pid_t) -> AXUIElement? {
        let app = AXUIElementCreateApplication(pid)
        return element(app, kAXExtrasMenuBarAttribute)
    }

    static func perform(_ element: AXUIElement, _ action: String) -> Bool {
        AXUIElementPerformAction(element, action as CFString) == .success
    }
}
