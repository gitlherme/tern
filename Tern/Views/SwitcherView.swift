import AppKit
import SwiftUI

struct SwitcherView: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            content
            footer
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
        .padding(12)
    }

    private var header: some View {
        HStack {
            Image("MenuBarIcon")
                .foregroundStyle(.tint)
            Text(verbatim: "Tern")
                .font(.headline)
            Spacer()
            if model.isTrusted && !model.windows.isEmpty {
                Text("\(model.windows.count) janelas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if !model.isTrusted {
            PermissionCard()
        } else if model.windows.isEmpty {
            EmptyWindowsCard()
        } else {
            windowStrip
        }
    }

    private var windowStrip: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(model.windows.enumerated()), id: \.element.id) { index, window in
                        WindowCard(
                            window: window,
                            selected: index == model.selectedIndex,
                            preview: model.thumbnails[window.windowID],
                            showsCaptureHint: !model.canCaptureScreen
                        )
                        .id(window.id)
                        .onTapGesture {
                            model.select(index)
                            model.confirm()
                        }
                    }
                }
                // Folga para a borda de 2pt e o scale de 1.03 do card destacado não serem cortados.
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
            .onChange(of: model.selectedIndex) { newValue in
                guard model.windows.indices.contains(newValue) else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(model.windows[newValue].id, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 188)
    }

    private var footer: some View {
        Text(footerText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    private var footerText: String {
        if !model.isTrusted {
            return String(localized: "O seletor só lista e troca janelas depois da permissão de Acessibilidade.")
        }
        if model.windows.isEmpty {
            return String(localized: "Abra um app ou confira as exclusões em Ajustes.")
        }
        if !model.canCaptureScreen {
            return String(localized: "Ligue Gravação da tela nos Ajustes para ver a prévia.  ⌫ oculta o app   ⌥⌫ só esta janela")
        }
        return String(localized: "⇥ próximo   ⇧⇥ anterior   ⌫ ocultar app   ⌥⌫ só esta janela   ⏎ abrir   esc fechar")
    }
}

struct WindowCard: View {
    let window: WindowInfo
    let selected: Bool
    let preview: NSImage?
    let showsCaptureHint: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                previewPane
                Image(nsImage: window.icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 28, height: 28)
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)
                    .padding(8)
            }
            Text(window.displayTitle)
                .font(.system(size: 12, weight: selected ? .semibold : .medium))
                .lineLimit(2)
                .frame(height: 32, alignment: .topLeading)
            HStack(spacing: 6) {
                Text(window.appName)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                if window.isMinimized {
                    Text("minimizada")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .frame(width: 228, height: 228)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(selected ? Color.accentColor.opacity(0.22) : Color.black.opacity(0.18))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(selected ? Color.accentColor : Color.white.opacity(0.08), lineWidth: selected ? 2 : 1)
        )
        .scaleEffect(selected ? 1.03 : 1)
        .animation(.easeOut(duration: 0.1), value: selected)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityLabel("\(window.appName), \(window.displayTitle)")
    }

    @ViewBuilder
    private var previewPane: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color.black.opacity(0.35))
            .frame(width: 208, height: 124)
            .overlay {
                if let preview {
                    Image(nsImage: preview)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFill()
                        .frame(width: 208, height: 124)
                        .clipped()
                } else {
                    VStack(spacing: 6) {
                        Image(nsImage: window.icon)
                            .resizable()
                            .frame(width: 44, height: 44)
                        if showsCaptureHint {
                            Text("Sem prévia")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct PermissionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Acessibilidade desligada", systemImage: "hand.raised.fill")
                .font(.headline)
            Text("O macOS só deixa o Tern listar e focar janelas de outros apps depois que você conceder Acessibilidade. Sem isso, o atalho não consegue trocar de janela.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Button("Abrir Ajustes do Sistema") {
                    AccessibilityPermission.openSystemSettings()
                }
                .keyboardShortcut(.defaultAction)
                Button("Pedir permissão") {
                    AccessibilityPermission.promptIfNeeded()
                }
                Button("Ajustes do Tern") {
                    AppModel.shared.openSettings()
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.orange.opacity(0.14))
        )
    }
}

struct EmptyWindowsCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Nenhuma janela para trocar", systemImage: "rectangle.slash")
                .font(.headline)
            Text("Não achei janelas de apps regulares agora. Se você tem janelas abertas, olhe as exclusões em Ajustes — ou feche e abra o Tern de novo depois de mudar permissões.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Abrir Ajustes") {
                AppModel.shared.openSettings()
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
    }
}
