import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("Geral", systemImage: "keyboard") }
            ExclusionsSettingsView()
                .tabItem { Label("Exclusões", systemImage: "eye.slash") }
            ModesSettingsView()
                .tabItem { Label("Modos", systemImage: "moon") }
        }
        .frame(minWidth: 560, minHeight: 460)
        .onAppear {
            model.refreshRunningApps()
            model.refreshWindows()
        }
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Atalho global")
                    Spacer()
                    HotkeyRecorderView(chord: model.hotkey) { newChord in
                        model.setHotkey(newChord)
                    }
                }
                Text("Padrão: ⌥⇥, no estilo do alt-tab.app. Segure os modificadores e toque a tecla para gravar outro atalho. Não use ⌘⇥ — o macOS reserva esse atalho para o seletor de apps.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Seletor")
            }

            Section {
                HStack(spacing: 10) {
                    Image(systemName: model.isTrusted ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundStyle(model.isTrusted ? Color.green : Color.orange)
                        .imageScale(.large)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.isTrusted ? String(localized: "Acessibilidade concedida") : String(localized: "Acessibilidade necessária"))
                            .font(.headline)
                        Text(model.isTrusted
                             ? String(localized: "O Tern pode listar janelas e trazer a escolhida para a frente.")
                             : String(localized: "Sem esta permissão o atalho abre só o aviso, sem trocar de janela."))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !model.isTrusted {
                        Button("Abrir Ajustes do Sistema") {
                            AccessibilityPermission.openSystemSettings()
                        }
                    }
                }
                Text("Monitoramento de entrada não é necessário se a Acessibilidade estiver ligada: o Tern intercepta o atalho na origem para ele não disparar também no browser. Sem essa interceptação, ⌥⇥ vaza para o app da frente.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if model.isTrusted && !model.isInterceptingKeys {
                    Text("Não consegui interceptar o teclado. Ligue Monitoramento de entrada para o Tern, ou feche e abra o Tern de novo.")
                        .font(.callout)
                        .foregroundStyle(.orange)
                    Button("Abrir Monitoramento de entrada") {
                        AccessibilityPermission.openInputMonitoringSettings()
                    }
                }

                HStack(spacing: 10) {
                    Image(systemName: model.canCaptureScreen ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundStyle(model.canCaptureScreen ? Color.green : Color.orange)
                        .imageScale(.large)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(model.canCaptureScreen ? String(localized: "Gravação da tela concedida") : String(localized: "Gravação da tela para prévias"))
                            .font(.headline)
                        Text(model.canCaptureScreen
                             ? String(localized: "O seletor mostra uma miniatura de cada janela.")
                             : String(localized: "Sem esta permissão os cards ficam só com o ícone do app. O seletor continua trocando de janela."))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        if !model.canCaptureScreen {
                            Button("Pedir permissão") {
                                ScreenCapturePermission.request {
                                    model.canCaptureScreen = ScreenCapturePermission.isTrusted
                                    if model.canCaptureScreen {
                                        model.refreshThumbnails()
                                    }
                                }
                            }
                            if ScreenCapturePermission.isRunningFromBuildFolder {
                                Button("Mostrar Tern.app no Finder") {
                                    ScreenCapturePermission.revealInFinder()
                                }
                            }
                        }
                        Button("Abrir Ajustes do Sistema") {
                            ScreenCapturePermission.openSystemSettings()
                        }
                    }
                }
                Text("Se o Tern não aparecer em Gravação da Tela, clique no + embaixo da lista, escolha o Tern em Aplicativos e ligue a chave. Depois saia do Tern pela barra de menus e abra de novo.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Permissões")
            }

            Section {
                Toggle("Abrir o Tern ao iniciar sessão", isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                ))
                if model.launchAtLoginNeedsApproval {
                    HStack {
                        Text("Falta aprovar o Tern em Itens de Início.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Abrir Itens de Início") {
                            LaunchAtLogin.openSystemSettings()
                        }
                    }
                }
                Text("O Tern fica só na barra de menus, sem ícone no Dock. Clique no ícone de retângulos para abrir o seletor, os ajustes ou sair.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                Button("Mostrar boas-vindas") {
                    model.openWelcome()
                }
            } header: {
                Text("Barra de menus")
            }

            Section {
                UpdateSettingsRow()
            } header: {
                Text("Atualizações")
            }
        }
        .formStyle(.grouped)
        .padding(8)
    }
}

struct ExclusionsSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var showAppPicker = false
    @State private var showWindowPicker = false
    @State private var showRuleEditor = false

    var body: some View {
        Form {
            Section {
                if model.exclusions.apps.isEmpty {
                    emptyApps
                } else {
                    ForEach(model.exclusions.apps) { app in
                        HStack(spacing: 10) {
                            Image(nsImage: AppIcon.image(bundleID: app.bundleID, pid: 0))
                                .resizable()
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(app.displayName)
                                if let until = app.until {
                                    Group {
                                        if Calendar.current.isDateInToday(until) {
                                            Text("Volta às \(until, style: .time)")
                                        } else {
                                            Text("Volta amanhã às \(until, style: .time)")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                                } else {
                                    Text(app.bundleID)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }
                            Spacer()
                            Button(role: .destructive) {
                                model.removeAppExclusion(bundleID: app.bundleID)
                            } label: {
                                Text("Remover")
                            }
                        }
                    }
                }
                Button("Adicionar app em execução…") {
                    model.refreshRunningApps()
                    showAppPicker = true
                }
            } header: {
                Text("Apps ocultos")
            } footer: {
                Text("Um app nesta lista some por completo do seletor, em todas as janelas. No seletor, ⌫ esconde o app destacado e ⇧⌫ esconde por 1 hora.")
            }

            Section {
                if model.exclusions.windows.isEmpty {
                    Label("Nenhuma janela oculta. Use isto só quando quiser esconder uma janela e manter as outras do mesmo app.", systemImage: "eye.slash")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(model.exclusions.windows) { item in
                        HStack(spacing: 10) {
                            Image(nsImage: AppIcon.image(bundleID: item.bundleID, pid: 0))
                                .resizable()
                                .frame(width: 24, height: 24)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.displayTitle)
                                Text(verbatim: "\(item.appName) · \(item.bundleID)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                model.removeWindowExclusion(item)
                            } label: {
                                Text("Remover")
                            }
                        }
                    }
                }
                Button("Adicionar janela aberta…") {
                    model.refreshWindows()
                    showWindowPicker = true
                }
            } header: {
                Text("Janelas ocultas")
            } footer: {
                Text("A exclusão de janela usa o título exato: se ele mudar, a janela volta. Para isso, use uma regra por título. No seletor, ⌥⌫ oculta só a janela destacada.")
            }

            Section {
                if model.exclusions.titleRules.isEmpty {
                    Label("Nenhuma regra. Use para esconder janelas pelo título, como Picture in Picture ou as barras flutuantes do Zoom.", systemImage: "text.magnifyingglass")
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(model.exclusions.titleRules) { rule in
                        HStack(spacing: 10) {
                            Image(systemName: "text.magnifyingglass")
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(verbatim: rule.pattern)
                                Text(rule.appName ?? String(localized: "Qualquer app"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(role: .destructive) {
                                model.removeTitleRule(rule)
                            } label: {
                                Text("Remover")
                            }
                        }
                    }
                }
                Button("Adicionar regra…") {
                    model.refreshRunningApps()
                    showRuleEditor = true
                }
            } header: {
                Text("Regras por título")
            } footer: {
                // String já traduzida: o Text com chave leria os * como itálico do Markdown.
                Text(String(localized: "Sem *, esconde as janelas cujo título contém o texto. Com *, o padrão cobre o título todo: Picture* esconde “Picture in Picture”. Maiúsculas e acentos não importam, e a regra continua valendo quando o título muda."))
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .sheet(isPresented: $showAppPicker) {
            RunningAppsPicker(isPresented: $showAppPicker)
                .environmentObject(model)
        }
        .sheet(isPresented: $showWindowPicker) {
            OpenWindowsPicker(isPresented: $showWindowPicker)
                .environmentObject(model)
        }
        .sheet(isPresented: $showRuleEditor) {
            TitleRuleEditor(isPresented: $showRuleEditor)
                .environmentObject(model)
        }
    }

    private var emptyApps: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Nenhum app oculto", systemImage: "eye")
                .font(.headline)
            Text("Apps e janelas ocultos não aparecem no seletor. Adicione um app em execução para experimentá-lo: com 5 apps abertos e um oculto, o atalho mostra só os outros 4.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct ModesSettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var pickingForMode: UUID?

    private var activeBinding: Binding<UUID?> {
        Binding(get: { model.exclusions.activeModeID }, set: { model.setActiveMode($0) })
    }

    var body: some View {
        Form {
            Section {
                Picker("Modo ativo", selection: activeBinding) {
                    Text("Nenhum").tag(UUID?.none)
                    ForEach(model.exclusions.modes) { mode in
                        Text(verbatim: mode.name).tag(UUID?.some(mode.id))
                    }
                }
            } footer: {
                Text("Um modo esconde apps a mais enquanto está ativo, além dos apps ocultos de sempre. Troque pelo menu do Tern ou deixe um Foco do macOS trocar sozinho.")
            }

            ForEach(model.exclusions.modes) { mode in
                Section {
                    TextField("Nome", text: Binding(
                        get: { mode.name },
                        set: { model.renameMode(mode.id, to: $0) }
                    ))
                    if mode.apps.isEmpty {
                        Text("Nenhum app neste modo ainda.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(mode.apps) { app in
                        HStack(spacing: 10) {
                            Image(nsImage: AppIcon.image(bundleID: app.bundleID, pid: 0))
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text(app.displayName)
                            Spacer()
                            Button(role: .destructive) {
                                model.removeAppFromMode(mode.id, bundleID: app.bundleID)
                            } label: {
                                Text("Remover")
                            }
                        }
                    }
                    HStack {
                        Button("Adicionar app…") {
                            model.refreshRunningApps()
                            pickingForMode = mode.id
                        }
                        Spacer()
                        Button("Apagar modo", role: .destructive) {
                            model.deleteMode(mode.id)
                        }
                    }
                } header: {
                    Text(verbatim: mode.name)
                }
            }

            Section {
                Button("Novo modo") {
                    model.createMode()
                }
            }

            Section {
                Text("Em Ajustes do Sistema › Foco, escolha um Foco (como Trabalho) e vá em Filtros de Foco › Adicionar Filtro › Tern. Escolha o modo: quando o Foco ligar, o modo liga junto; quando desligar, o Tern volta para nenhum modo.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button("Abrir ajustes de Foco") {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Focus-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }
            } header: {
                Text("Ligar a um Foco do macOS")
            }
        }
        .formStyle(.grouped)
        .padding(8)
        .sheet(isPresented: Binding(get: { pickingForMode != nil }, set: { if !$0 { pickingForMode = nil } })) {
            if let modeID = pickingForMode {
                ModeAppPicker(modeID: modeID, isPresented: Binding(get: { pickingForMode != nil }, set: { if !$0 { pickingForMode = nil } }))
                    .environmentObject(model)
            }
        }
    }
}

struct ModeAppPicker: View {
    @EnvironmentObject private var model: AppModel
    let modeID: UUID
    @Binding var isPresented: Bool

    private var candidates: [RunningAppInfo] {
        let inMode = Set(model.exclusions.modes.first { $0.id == modeID }?.apps.map(\.bundleID) ?? [])
        return model.runningApps.filter { !inMode.contains($0.bundleID) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Adicionar app ao modo")
                .font(.title2.weight(.semibold))
            Text("Enquanto o modo estiver ativo, o app some do seletor.")
                .foregroundStyle(.secondary)
            if candidates.isEmpty {
                ContentUnavailableHint(
                    title: "Nada para adicionar",
                    detail: "Todos os apps em execução já estão neste modo, ou não há apps abertos."
                )
            } else {
                List(candidates) { app in
                    Button {
                        model.addAppToMode(modeID, bundleID: app.bundleID, name: app.name)
                        isPresented = false
                    } label: {
                        HStack(spacing: 10) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                            Text(app.name)
                                .foregroundStyle(.primary)
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Spacer()
                Button("Cancelar") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 440, height: 420)
    }
}

struct RunningAppsPicker: View {
    @EnvironmentObject private var model: AppModel
    @Binding var isPresented: Bool
    @State private var duration: HideDuration = .always

    private var candidates: [RunningAppInfo] {
        model.runningApps.filter { app in
            !model.exclusions.apps.contains(where: { $0.bundleID == app.bundleID })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ocultar app")
                .font(.title2.weight(.semibold))
            Text("O app deixa de aparecer no seletor pelo tempo escolhido.")
                .foregroundStyle(.secondary)
            Picker("Por quanto tempo", selection: $duration) {
                Text("Sempre").tag(HideDuration.always)
                Text("1 hora").tag(HideDuration.oneHour)
                Text("Até amanhã").tag(HideDuration.untilTomorrow)
            }
            .pickerStyle(.segmented)
            if candidates.isEmpty {
                ContentUnavailableHint(
                    title: "Nada para adicionar",
                    detail: "Todos os apps regulares em execução já estão ocultos, ou não há apps abertos."
                )
            } else {
                List(candidates) { app in
                    Button {
                        model.excludeApp(bundleID: app.bundleID, name: app.name, duration: duration)
                        isPresented = false
                    } label: {
                        HStack(spacing: 10) {
                            Image(nsImage: app.icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading) {
                                Text(app.name)
                                    .foregroundStyle(.primary)
                                Text(app.bundleID)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Spacer()
                Button("Cancelar") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 440, height: 420)
    }
}

struct OpenWindowsPicker: View {
    @EnvironmentObject private var model: AppModel
    @Binding var isPresented: Bool

    private var candidates: [WindowInfo] {
        WindowEnumerator()
            .enumerate(exclusions: model.exclusions, ignoringBundleID: Bundle.main.bundleIdentifier)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ocultar janela")
                .font(.title2.weight(.semibold))
            Text("Só esta janela some. As outras do mesmo app continuam no seletor.")
                .foregroundStyle(.secondary)
            if candidates.isEmpty {
                ContentUnavailableHint(
                    title: "Nenhuma janela listável",
                    detail: "Abra uma janela ou remova exclusões de app. Sem Acessibilidade, os títulos podem vir vazios."
                )
            } else {
                List(candidates) { window in
                    Button {
                        model.excludeWindow(window)
                        isPresented = false
                    } label: {
                        HStack(spacing: 10) {
                            Image(nsImage: window.icon)
                                .resizable()
                                .frame(width: 28, height: 28)
                            VStack(alignment: .leading) {
                                Text(window.displayTitle)
                                    .foregroundStyle(.primary)
                                Text(window.appName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            HStack {
                Spacer()
                Button("Cancelar") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 440, height: 420)
    }
}

struct TitleRuleEditor: View {
    @EnvironmentObject private var model: AppModel
    @Binding var isPresented: Bool
    @State private var pattern = ""
    @State private var scopeBundleID = ""

    /// Janelas abertas agora (sem as já ocultas) que a regra esconderia.
    private var preview: [WindowInfo] {
        let rule = draft
        guard !pattern.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        return WindowEnumerator()
            .enumerate(exclusions: model.exclusions, ignoringBundleID: Bundle.main.bundleIdentifier)
            .filter { rule.matches(bundleID: $0.bundleID, title: $0.title) }
    }

    private var draft: TitleRule {
        let app = model.runningApps.first { $0.bundleID == scopeBundleID }
        return TitleRule(pattern: pattern, bundleID: scopeBundleID.isEmpty ? nil : scopeBundleID, appName: app?.name)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nova regra por título")
                .font(.title2.weight(.semibold))
            Text("Janelas cujo título combina com a regra somem do seletor, mesmo que o título mude depois.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            TextField("Texto do título", text: $pattern, prompt: Text(verbatim: "Picture in Picture"))
                .textFieldStyle(.roundedBorder)
            Picker("App", selection: $scopeBundleID) {
                Text("Qualquer app").tag("")
                ForEach(model.runningApps) { app in
                    Text(verbatim: app.name).tag(app.bundleID)
                }
            }
            GroupBox {
                let matches = preview
                VStack(alignment: .leading, spacing: 6) {
                    if pattern.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("Digite um texto para ver quais janelas abertas a regra esconde.")
                            .foregroundStyle(.secondary)
                    } else if matches.isEmpty {
                        Text("Nenhuma janela aberta agora combina com a regra.")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Esconde agora: \(matches.count) janelas")
                            .font(.headline)
                        ForEach(matches.prefix(5)) { window in
                            Text(verbatim: "\(window.appName) — \(window.displayTitle)")
                                .font(.callout)
                                .lineLimit(1)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
            HStack {
                Spacer()
                Button("Cancelar") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Button("Adicionar") {
                    let rule = draft
                    model.addTitleRule(pattern: rule.pattern, bundleID: rule.bundleID, appName: rule.appName)
                    isPresented = false
                }
                .keyboardShortcut(.defaultAction)
                .disabled(pattern.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 460, height: 420)
    }
}

struct ContentUnavailableHint: View {
    let title: LocalizedStringKey
    let detail: LocalizedStringKey

    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct UpdateSettingsRow: View {
    @ObservedObject private var updates = UpdateService.shared

    var body: some View {
        Toggle("Procurar atualizações automaticamente", isOn: $updates.automaticallyChecks)
        HStack {
            Text("Versão \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "")")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Procurar agora") {
                updates.checkForUpdates()
            }
        }
    }
}
