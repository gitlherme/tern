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
            Image(systemName: "rectangle.on.rectangle")
                .foregroundStyle(.tint)
            Text("Vez")
                .font(.headline)
            Spacer()
            if model.isTrusted && !model.windows.isEmpty {
                Text("\(model.windows.count) janela\(model.windows.count == 1 ? "" : "s")")
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
                            selected: index == model.selectedIndex
                        )
                        .id(window.id)
                        .onTapGesture {
                            model.select(index)
                            model.confirm()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: model.selectedIndex) { newValue in
                guard model.windows.indices.contains(newValue) else { return }
                withAnimation(.easeOut(duration: 0.12)) {
                    proxy.scrollTo(model.windows[newValue].id, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 168)
    }

    private var footer: some View {
        Text(footerText)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
    }

    private var footerText: String {
        if !model.isTrusted {
            return "O seletor só lista e troca janelas depois da permissão de Acessibilidade."
        }
        if model.windows.isEmpty {
            return "Abra um app ou remova exclusões em Ajustes."
        }
        return "⇥ próximo   ⇧⇥ anterior   ⌫ ocultar app   ⌥⌫ só esta janela   ⏎ abrir   esc fechar"
    }
}

struct WindowCard: View {
    let window: WindowInfo
    let selected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: window.icon)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 56, height: 56)
                .shadow(color: .black.opacity(0.18), radius: 4, y: 2)

            Text(window.displayTitle)
                .font(.system(size: 12, weight: selected ? .semibold : .medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 32)

            Text(window.appName)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if !window.isOnscreen {
                Text("minimizada")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(width: 148, height: 168)
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
}

struct PermissionCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Acessibilidade desligada", systemImage: "hand.raised.fill")
                .font(.headline)
            Text("O macOS só deixa o Vez listar e focar janelas de outros apps depois que você conceder Acessibilidade. Sem isso, o atalho não consegue trocar de janela.")
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
                Button("Ajustes do Vez") {
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
            Text("Não há janelas visíveis, ou todos os apps abertos estão na lista de exclusões. Remova uma exclusão ou abra outra janela.")
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
