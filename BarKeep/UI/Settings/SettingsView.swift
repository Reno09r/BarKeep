import SwiftUI

@MainActor
struct SettingsView: View {
    @ObservedObject private var localization = Localization.shared
    @ObservedObject private var launchService = LaunchAtLoginService.shared
    let permissions: PermissionsManager
    let layout: MenuBarLayoutController
    let hover: HoverRevealController

    @AppStorage("BarKeepHoverReveal") private var hoverReveal = false
    @State private var currentIconStyle: ControlIconStyle
    @State private var selectedTab = 0

    init(permissions: PermissionsManager, layout: MenuBarLayoutController, hover: HoverRevealController) {
        self.permissions = permissions
        self.layout = layout
        self.hover = hover
        _currentIconStyle = State(initialValue: layout.currentIconStyle)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            generalTab
                .tabItem { Label(Localization.tr(.generalTab), systemImage: "gear") }
                .tag(0)

            iconTab
                .tabItem { Label(Localization.tr(.iconTab), systemImage: "menubar.rectangle") }
                .tag(1)

            permissionsTab
                .tabItem { Label(Localization.tr(.permissionsTab), systemImage: "lock.shield") }
                .tag(2)

            aboutTab
                .tabItem { Label(Localization.tr(.aboutTab), systemImage: "info.circle") }
                .tag(3)
        }
        .frame(width: 480, height: 320)
        .padding(16)
    }

    // MARK: - Вкладка «Основные»

    private var generalTab: some View {
        Form {
            Section {
                Toggle(Localization.tr(.launchAtLogin), isOn: Binding(
                    get: { launchService.isEnabled },
                    set: { _ = launchService.set(enabled: $0) }
                ))

                Toggle(Localization.tr(.showOnHover), isOn: $hoverReveal)
                    .onChange(of: hoverReveal) { _, newValue in
                        if newValue { hover.start() } else { hover.stop() }
                    }

                Toggle(Localization.tr(.alwaysHiddenEnabled), isOn: Binding(
                    get: { layout.isAlwaysHiddenEnabled },
                    set: { layout.setAlwaysHidden(enabled: $0) }
                ))
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Вкладка «Иконка»

    private var iconTab: some View {
        Form {
            Section(header: Text(Localization.tr(.iconStyle))) {
                Picker("", selection: $currentIconStyle) {
                    ForEach(ControlIconStyle.allCases) { style in
                        Text(style.title).tag(style)
                    }
                }
                .pickerStyle(.radioGroup)
                .onChange(of: currentIconStyle) { _, newStyle in
                    layout.currentIconStyle = newStyle
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Вкладка «Разрешения»

    private var permissionsTab: some View {
        Form {
            Section {
                HStack {
                    Image(systemName: permissions.accessibility ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(permissions.accessibility ? .green : .orange)
                    Text("Accessibility")
                    Spacer()
                    Button(Localization.tr(.buttonOpenSettings)) {
                        permissions.requestAccessibility()
                    }
                }

                HStack {
                    Image(systemName: permissions.screenRecording ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(permissions.screenRecording ? .green : .orange)
                    Text(Localization.tr(.screenRecordingOk).replacingOccurrences(of: ": ✓", with: ""))
                    Spacer()
                    Button(Localization.tr(.buttonOpenSettings)) {
                        permissions.requestScreenRecording()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            permissions.refresh(force: true)
        }
    }

    // MARK: - Вкладка «О программе»

    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "menubar.rectangle")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
                .foregroundStyle(.tint)

            Text("BarKeep")
                .font(.title2.bold())

            Text(Localization.tr(.appVersion, Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider().padding(.vertical, 4)

            HStack(spacing: 16) {
                Button(Localization.tr(.copyReport)) {
                    // Копирование отчёта
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(AppEnvironment.summary, forType: .string)
                }

                Button(Localization.tr(.openLog)) {
                    Log.revealInFinder()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
