import XCTest
import SwiftUI
@testable import BarKeep

@MainActor
final class BarKeepTests: XCTestCase {
    func testTransliteration() {
        XCTAssertEqual(BarPanelView.transliterate("телеграм"), "telegram")
        XCTAssertEqual(BarPanelView.transliterate("хром"), "hrom")
        XCTAssertEqual(BarPanelView.transliterate("яндекс"), "yandeks")
        XCTAssertEqual(BarPanelView.transliterate("қазақша"), "kazaksha")
    }

    func testNormalization() {
        XCTAssertEqual(BarPanelView.normalized("TELEGRAM"), "telegram")
        XCTAssertEqual(BarPanelView.normalized("Café"), "cafe")
    }

    func testMenuBarItemDisplay() {
        let normalItem = MenuBarItem(
            windowID: 101,
            ownerPID: 1000,
            ownerName: "Slack",
            bundleIdentifier: "com.tinyspeck.slackmacgap",
            title: nil,
            frame: CGRect(x: 500, y: 0, width: 24, height: 24),
            isOnScreen: true,
            axElement: nil
        )
        XCTAssertEqual(normalItem.displayName, "Slack")
        XCTAssertFalse(normalItem.isOffscreen)

        let offscreenItem = MenuBarItem(
            windowID: 102,
            ownerPID: 1001,
            ownerName: "Discord",
            bundleIdentifier: "com.hnc.Discord",
            title: nil,
            frame: CGRect(x: -500, y: 0, width: 24, height: 24),
            isOnScreen: false,
            axElement: nil
        )
        XCTAssertTrue(offscreenItem.isOffscreen)
    }

    func testControlCenterItemDisplayNames() {
        Localization.shared.setLanguage(.en)
        let wifi = MenuBarItem(
            windowID: 201,
            ownerPID: 500,
            ownerName: "ControlCenter",
            bundleIdentifier: "com.apple.controlcenter",
            title: "WiFi",
            frame: CGRect(x: 800, y: 0, width: 24, height: 24),
            isOnScreen: true,
            axElement: nil
        )
        XCTAssertEqual(wifi.displayName, "Wi-Fi")

        let bento = MenuBarItem(
            windowID: 202,
            ownerPID: 500,
            ownerName: "ControlCenter",
            bundleIdentifier: "com.apple.controlcenter",
            title: "BentoBox",
            frame: CGRect(x: 850, y: 0, width: 24, height: 24),
            isOnScreen: true,
            axElement: nil
        )
        XCTAssertEqual(bento.displayName, "Control Center")
    }

    func testCanManageProtectsAppleProcesses() {
        let appleItem = MenuBarItem(
            windowID: 301,
            ownerPID: 1,
            ownerName: "ControlCenter",
            bundleIdentifier: "com.apple.controlcenter",
            title: nil,
            frame: CGRect(x: 900, y: 0, width: 24, height: 24),
            isOnScreen: true,
            axElement: nil
        )
        XCTAssertFalse(AppTerminator.canManage(item: appleItem))
    }

    func testControlIconStyles() {
        for style in ControlIconStyle.allCases {
            XCTAssertFalse(style.title.isEmpty)
            XCTAssertFalse(style.localizedTitle.isEmpty)
            XCTAssertNotNil(style.image(), "Style \(style.rawValue) must generate a valid icon")
        }
    }

    func testLocalizationKeys() {
        for lang in AppLanguage.allCases {
            Localization.shared.setLanguage(lang)
            XCTAssertFalse(Localization.tr(.launchAtLogin).isEmpty)
            XCTAssertFalse(Localization.tr(.preferences).isEmpty)
            XCTAssertFalse(Localization.tr(.iconStyle).isEmpty)
            XCTAssertFalse(Localization.tr(.alwaysHiddenEnabled).isEmpty)
            XCTAssertFalse(Localization.tr(.hotkeysTab).isEmpty)
            XCTAssertFalse(Localization.tr(.accessibilityDesc).isEmpty)
            XCTAssertFalse(Localization.tr(.statusGranted).isEmpty)
            XCTAssertFalse(Localization.tr(.resetAccessibility).isEmpty)
        }
        Localization.shared.setLanguage(.en)
    }

    func testSettingsInitialization() {
        let permissions = PermissionsManager()
        let layout = MenuBarLayoutController()
        let hover = HoverRevealController(layout: layout)
        let view = SettingsView(permissions: permissions, layout: layout, hover: hover)
        let hosting = NSHostingView(rootView: view)
        XCTAssertNotNil(hosting)
        XCTAssertEqual(SettingsTab.allCases.count, 5)
    }
}
