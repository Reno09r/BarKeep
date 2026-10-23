import AppKit
import ApplicationServices
import ScreenCaptureKit
import Combine

/// Состояние системных разрешений и запрос доступа.
@MainActor
final class PermissionsManager: ObservableObject {
    @Published private(set) var accessibility = false
    @Published private(set) var screenRecording = false
    private(set) var lastRefresh = Date.distantPast

    func refresh(force: Bool = false) {
        if !force, Date().timeIntervalSince(lastRefresh) < 0.5 { return }
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        accessibility = AXIsProcessTrustedWithOptions(options)
        screenRecording = CGPreflightScreenCaptureAccess()
        lastRefresh = Date()
    }

    var hasRequiredPermissions: Bool { accessibility }

    func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        openAccessibilitySettings()
        refresh(force: true)
    }

    func requestScreenRecording() {
        // На macOS 15 CGRequestScreenCaptureAccess() не показывает диалог,
        // а обращение к SCShareableContent — показывает.
        SCShareableContent.getWithCompletionHandler { _, _ in
            Task { @MainActor in self.refresh(force: true) }
        }
        openScreenRecordingSettings()
        refresh(force: true)
    }

    func openAccessibilitySettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func openScreenRecordingSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
    }

    /// Сбрасывает устаревшую регистрацию TCC для пересобранного приложения.
    func resetAccessibility() {
        let task = Process()
        task.launchPath = "/usr/bin/tccutil"
        task.arguments = ["reset", "Accessibility", "com.reno.barkeep"]
        try? task.run()
        task.waitUntilExit()
        refresh(force: true)
        requestAccessibility()
    }

    private func open(_ string: String) {
        guard let url = URL(string: string) else { return }
        NSWorkspace.shared.open(url)
    }
}
