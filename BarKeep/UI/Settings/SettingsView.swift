import SwiftUI
import AppKit

enum SettingsTab: Int, CaseIterable, Identifiable {
    case general
    case icon
    case hotkeys
    case permissions
    case about

    nonisolated var id: Int { rawValue }

    @MainActor
    var title: String {
        switch self {
        case .general: return Localization.tr(.generalTab)
        case .icon: return Localization.tr(.iconTab)
        case .hotkeys: return Localization.tr(.hotkeysTab)
        case .permissions: return Localization.tr(.permissionsTab)
        case .about: return Localization.tr(.aboutTab)
        }
    }

    var iconName: String {
        switch self {
        case .general: return "gearshape.fill"
        case .icon: return "menubar.rectangle"
        case .hotkeys: return "command"
        case .permissions: return "lock.shield.fill"
        case .about: return "info.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .general: return .gray
        case .icon: return .indigo
        case .hotkeys: return .purple
        case .permissions: return .orange
        case .about: return .blue
        }
    }
}

@MainActor
struct SettingsView: View {
    @ObservedObject private var localization = Localization.shared
    @ObservedObject private var launchService = LaunchAtLoginService.shared
    @ObservedObject var permissions: PermissionsManager
    let layout: MenuBarLayoutController
    let hover: HoverRevealController

    @AppStorage("BarKeepHoverReveal") private var hoverReveal = false
    @State private var currentIconStyle: ControlIconStyle
    @State private var selectedTab: SettingsTab = .general
    @State private var reportCopied = false

    init(permissions: PermissionsManager, layout: MenuBarLayoutController, hover: HoverRevealController) {
        self.permissions = permissions
        self.layout = layout
        self.hover = hover
        _currentIconStyle = State(initialValue: layout.currentIconStyle)
    }

    var body: some View {
        HStack(spacing: 0) {
            sidebarView
                .frame(width: 190)

            Divider()

            detailView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 620, idealWidth: 660, minHeight: 420, idealHeight: 460)
        .background(Color(nsColor: .windowBackgroundColor))
        .onReceive(Timer.publish(every: 0.8, on: .main, in: .common).autoconnect()) { _ in
            permissions.refresh()
        }
    }

    // MARK: - Сайдбар слева

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Логотип и заголовок
            HStack(spacing: 10) {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 1) {
                    Text("BarKeep")
                        .font(.headline.weight(.semibold))
                    Text(Localization.tr(.preferences).replacingOccurrences(of: "…", with: ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Divider()
                .padding(.bottom, 8)

            // Список вкладок
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 4) {
                    ForEach(SettingsTab.allCases) { tab in
                        sidebarButton(for: tab)
                    }
                }
                .padding(.horizontal, 10)
            }

            Spacer()

            // Версия внизу сайдбара
            VStack(spacing: 2) {
                Text(Localization.tr(.appVersion, appVersionString))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 12)
        }
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.6))
    }

    private func sidebarButton(for tab: SettingsTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            selectedTab = tab
        } label: {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(tab.iconColor.opacity(isSelected ? 0.9 : 0.15))
                        .frame(width: 24, height: 24)
                    Image(systemName: tab.iconName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : tab.iconColor)
                }

                Text(tab.title)
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Контентная область справа

    @ViewBuilder
    private var detailView: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 20) {
                switch selectedTab {
                case .general:
                    generalSettingsView
                case .icon:
                    iconSettingsView
                case .hotkeys:
                    hotkeysSettingsView
                case .permissions:
                    permissionsSettingsView
                case .about:
                    aboutSettingsView
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Вкладка 1: Основные

    private var generalSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            header(title: Localization.tr(.generalTab), subtitle: Localization.tr(.generalSubheader))

            settingsCard {
                // Запуск при входе
                settingRow(
                    title: Localization.tr(.launchAtLogin),
                    subtitle: Localization.tr(.launchAtLoginDesc)
                ) {
                    Toggle("", isOn: Binding(
                        get: { launchService.isEnabled },
                        set: { _ = launchService.set(enabled: $0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                cardDivider

                // Показывать при наведении
                settingRow(
                    title: Localization.tr(.showOnHover),
                    subtitle: Localization.tr(.showOnHoverDesc)
                ) {
                    Toggle("", isOn: $hoverReveal)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .onChange(of: hoverReveal) { _, newValue in
                            if newValue { hover.start() } else { hover.stop() }
                        }
                }

                cardDivider

                // Всегда скрытые
                settingRow(
                    title: Localization.tr(.alwaysHiddenEnabled),
                    subtitle: Localization.tr(.alwaysHiddenDesc)
                ) {
                    Toggle("", isOn: Binding(
                        get: { layout.isAlwaysHiddenEnabled },
                        set: { layout.setAlwaysHidden(enabled: $0) }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }
            }

            settingsCard {
                settingRow(
                    title: Localization.tr(.language),
                    subtitle: Localization.tr(.languageDesc)
                ) {
                    Picker("", selection: Binding(
                        get: { localization.current },
                        set: { localization.setLanguage($0) }
                    )) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: 130)
                }
            }
        }
    }

    // MARK: - Вкладка 2: Внешний вид / Иконка

    private var iconSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            header(title: Localization.tr(.iconTab), subtitle: Localization.tr(.iconSubheader))

            // Интерактивный предпросмотр в меню-баре
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.tr(.iconPreview))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                menuBarPreview
            }

            // Выбор стиля
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.tr(.iconStyle))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                settingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(ControlIconStyle.allCases.enumerated()), id: \.element.id) { index, style in
                            if index > 0 {
                                cardDivider
                            }
                            iconStyleRow(style: style)
                        }
                    }
                }
            }

            // Управление панелью и сброс
            settingsCard {
                settingRow(
                    title: Localization.tr(.hiddenPanel),
                    subtitle: Localization.tr(.openHiddenPanelDesc)
                ) {
                    Button(Localization.tr(.openHiddenPanel)) {
                        CommandBus.send("panel")
                    }
                }

                cardDivider

                settingRow(
                    title: Localization.tr(.restoreAllIcons),
                    subtitle: Localization.tr(.resetIconsDesc)
                ) {
                    Button(role: .destructive) {
                        layout.resetAll()
                    } label: {
                        Text(Localization.tr(.restoreAllIcons))
                    }
                }
            }
        }
    }

    private var menuBarPreview: some View {
        HStack(spacing: 12) {
            // Левая часть меню-бара
            HStack(spacing: 8) {
                Image(systemName: "apple.logo")
                    .font(.system(size: 12))
                Text("Finder")
                    .font(.system(size: 12, weight: .semibold))
                Text("File")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                Text("Edit")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(.primary.opacity(0.85))

            Spacer()

            // Правая часть меню-бара
            HStack(spacing: 10) {
                // Иконка BarKeep с подсветкой
                HStack(spacing: 4) {
                    if let img = currentIconStyle.image() {
                        Image(nsImage: img)
                            .renderingMode(.template)
                            .interpolation(.high)
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.accentColor.opacity(0.2))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Color.accentColor.opacity(0.5), lineWidth: 1)
                )

                Image(systemName: "wifi")
                    .font(.system(size: 11))
                Image(systemName: "battery.100")
                    .font(.system(size: 11))
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                Text("9:41")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundStyle(.primary.opacity(0.85))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func iconStyleRow(style: ControlIconStyle) -> some View {
        let isSelected = currentIconStyle == style
        return Button {
            currentIconStyle = style
            layout.currentIconStyle = style
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.04))
                        .frame(width: 32, height: 32)
                    if let img = style.image() {
                        Image(nsImage: img)
                            .renderingMode(.template)
                            .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                    }
                }

                Text(style.localizedTitle)
                    .font(.system(size: 13, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(Color.primary)

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Вкладка 3: Горячие клавиши

    private var hotkeysSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            header(title: Localization.tr(.hotkeysTab), subtitle: Localization.tr(.hotkeyTip))

            settingsCard {
                hotkeyRow(
                    title: Localization.tr(.hiddenPanel),
                    subtitle: Localization.tr(.hotkeyPanelDesc),
                    keys: ["⌃", "⌥", "⌘", "H"]
                )

                cardDivider

                hotkeyRow(
                    title: Localization.tr(.sectionAlwaysHidden),
                    subtitle: Localization.tr(.hotkeyAlwaysHiddenDesc),
                    keys: ["⌃", "⌥", "⌘", "A"]
                )

                cardDivider

                hotkeyRow(
                    title: Localization.tr(.restoreAllIcons),
                    subtitle: Localization.tr(.hotkeyResetDesc),
                    keys: ["⌃", "⌥", "⌘", "R"]
                )
            }
        }
    }

    private func hotkeyRow(title: String, subtitle: String, keys: [String]) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 4) {
                ForEach(keys, id: \.self) { key in
                    keyBadge(key)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func keyBadge(_ key: String) -> some View {
        Text(key)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary)
            .frame(minWidth: 22, minHeight: 22)
            .padding(.horizontal, 3)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .shadow(color: Color.black.opacity(0.12), radius: 1, x: 0, y: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.primary.opacity(0.12), lineWidth: 1)
            )
    }

    // MARK: - Вкладка 4: Разрешения

    private var permissionsSettingsView: some View {
        VStack(alignment: .leading, spacing: 18) {
            header(title: Localization.tr(.permissionsTab), subtitle: Localization.tr(.permissionsSubheader))

            settingsCard {
                // Accessibility
                permissionRow(
                    title: "Accessibility",
                    subtitle: Localization.tr(.accessibilityDesc),
                    isGranted: permissions.accessibility,
                    isRequired: true,
                    onReset: {
                        permissions.resetAccessibility()
                    }
                ) {
                    permissions.requestAccessibility()
                }

                cardDivider

                // Screen Recording
                permissionRow(
                    title: Localization.tr(.screenRecordingOk).replacingOccurrences(of: ": ✓", with: ""),
                    subtitle: Localization.tr(.screenRecordingDesc),
                    isGranted: permissions.screenRecording,
                    isRequired: false,
                    onReset: nil
                ) {
                    permissions.requestScreenRecording()
                }
            }

            if !permissions.accessibility {
                Text(Localization.tr(.resetAccessibilityDesc))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            HStack {
                Spacer()
                Button {
                    permissions.refresh(force: true)
                } label: {
                    Label(Localization.tr(.checkPermissions), systemImage: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            permissions.refresh(force: true)
        }
    }

    private func permissionRow(
        title: String,
        subtitle: String,
        isGranted: Bool,
        isRequired: Bool,
        onReset: (() -> Void)? = nil,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: isGranted ? "checkmark.circle.fill" : (isRequired ? "exclamationmark.triangle.fill" : "info.circle.fill"))
                .font(.system(size: 20))
                .foregroundStyle(isGranted ? .green : (isRequired ? .orange : .blue))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 13, weight: .medium))

                    Text(isGranted ? Localization.tr(.statusGranted) : (isRequired ? Localization.tr(.statusRequired) : Localization.tr(.statusOptional)))
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isGranted ? Color.green.opacity(0.15) : (isRequired ? Color.orange.opacity(0.15) : Color.blue.opacity(0.15)))
                        )
                        .foregroundStyle(isGranted ? Color.green : (isRequired ? Color.orange : Color.blue))
                        .fixedSize()
                }

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                if !isGranted, let onReset {
                    Button(Localization.tr(.resetAccessibility)) {
                        onReset()
                    }
                    .buttonStyle(.link)
                    .font(.caption)
                }

                Button(Localization.tr(.buttonOpenSettings)) {
                    action()
                }
                .fixedSize()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Вкладка 5: О программе

    private var aboutSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Хиро-блок с логотипом
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.indigo],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                        .shadow(color: Color.indigo.opacity(0.3), radius: 6, x: 0, y: 3)

                    Image(systemName: "menubar.rectangle")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("BarKeep")
                        .font(.title2.weight(.bold))
                    Text(Localization.tr(.appVersion, appVersionString))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("macOS menu bar icon manager")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                Spacer()
            }
            .padding(.bottom, 4)

            // Информация о системе
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.tr(.systemInfo))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                settingsCard {
                    systemInfoRow(title: "macOS", value: osVersionString)
                    cardDivider
                    systemInfoRow(title: Localization.tr(.menuBarHeight), value: "\(Int(ItemActivator.menuBarHeight)) pt")
                    cardDivider
                    systemInfoRow(
                        title: Localization.tr(.conflictingApps),
                        value: AppEnvironment.conflictingManagerName ?? Localization.tr(.noConflictsDetected),
                        isWarning: AppEnvironment.conflictingManagerName != nil
                    )
                }
            }

            // Диагностика и журналы
            VStack(alignment: .leading, spacing: 8) {
                Text(Localization.tr(.diagnosticsAndLogs))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                settingsCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Localization.tr(.copyReport))
                                .font(.system(size: 13, weight: .medium))
                            Text(Localization.tr(.copyReportDesc))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(reportCopied ? Localization.tr(.copied) : Localization.tr(.copy)) {
                            let pasteboard = NSPasteboard.general
                            pasteboard.clearContents()
                            pasteboard.setString(AppEnvironment.summary, forType: .string)
                            reportCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                reportCopied = false
                            }
                        }
                        .disabled(reportCopied)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    cardDivider

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Localization.tr(.openLog))
                                .font(.system(size: 13, weight: .medium))
                            Text(Localization.tr(.openLogDesc))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(Localization.tr(.open)) {
                            Log.revealInFinder()
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
    }

    private func systemInfoRow(title: String, value: String, isWarning: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(isWarning ? Color.orange : Color.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - Общие UI-компоненты

    private func header(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 20, weight: .bold))
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func settingRow<Control: View>(
        title: String,
        subtitle: String,
        @ViewBuilder control: () -> Control
    ) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            control()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var cardDivider: some View {
        Divider()
            .padding(.leading, 16)
    }

    private var appVersionString: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1"
    }

    private var osVersionString: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }
}
