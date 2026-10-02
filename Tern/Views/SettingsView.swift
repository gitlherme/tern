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
                        Text(model.isTrusted ? "Acessibilidade concedida" : "Acessibilidade necessária")
                            .font(.headline)
                        Text(model.isTrusted
                             ? "O Tern pode listar janelas e trazer a escolhida para a frente."
                             : "Sem esta permissão o atalho abre só o aviso, sem trocar de janela.")
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
                    Text("Não consegui interceptar o teclado neste processo. Ligue Monitoramento de entrada para o Tern, ou feche o app e rode de novo pelo Xcode.")
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
                        Text(model.canCaptureScreen ? "Gravação da tela concedida" : "Gravação da tela para prévias")
                            .font(.headline)
                        Text(model.canCaptureScreen
                             ? "O seletor mostra uma miniatura de cada janela."
                             : "Sem esta permissão os cards ficam só com o ícone do app. O seletor continua trocando de janela.")
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
                            Button("Mostrar Tern.app no Finder") {
                                ScreenCapturePermission.revealInFinder()
                            }
                        }
                        Button("Abrir Ajustes do Sistema") {
                            ScreenCapturePermission.openSystemSettings()
                        }
                    }
                }
                Text("O Tern não aparece sozinho em Screen & System Audio Recording quando roda pelo Xcode. Clique +, escolha ~/Applications/Tern.app (Pedir permissão / Mostrar no Finder deixa esse arquivo selecionado) e ligue o interruptor. Depois: barra de menus → Sair, e ⌘R.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Permissões")
            }

            Section {
                Text("O Tern fica só na barra de menus, sem ícone no Dock. Clique no ícone de retângulos para abrir o seletor, os ajustes ou sair.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Barra de menus")
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
                                Text(app.bundleID)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
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
                Text("Um app nesta lista some por completo do seletor, em todas as janelas. É o caminho principal para esconder, por exemplo, 1 app entre 5 abertos.")
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
                                Text("\(item.appName) · \(item.bundleID)")
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
                Text("A exclusão de janela usa o bundle id + título. Se o título mudar, a janela volta a aparecer. No seletor, ⌫ oculta o app; ⌥⌫ oculta só a janela.")
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

struct RunningAppsPicker: View {
    @EnvironmentObject private var model: AppModel
    @Binding var isPresented: Bool

    private var candidates: [RunningAppInfo] {
        model.runningApps.filter { app in
            !model.exclusions.apps.contains(where: { $0.bundleID == app.bundleID })
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ocultar app")
                .font(.title2.weight(.semibold))
            Text("O app deixa de aparecer no seletor até você removê-lo da lista.")
                .foregroundStyle(.secondary)
            if candidates.isEmpty {
                ContentUnavailableHint(
                    title: "Nada para adicionar",
                    detail: "Todos os apps regulares em execução já estão ocultos, ou não há apps abertos."
                )
            } else {
                List(candidates) { app in
                    Button {
                        model.excludeApp(bundleID: app.bundleID, name: app.name)
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

struct ContentUnavailableHint: View {
    let title: String
    let detail: String

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
