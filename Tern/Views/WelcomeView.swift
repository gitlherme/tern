import AppKit
import SwiftUI

/// Primeiro uso: onde o Tern mora, as permissões e o atalho, sem depender das notas da release.
struct WelcomeView: View {
    @EnvironmentObject private var model: AppModel
    @State private var triedSwitcher = false

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(spacing: 16) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 64, height: 64)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Boas-vindas ao Tern")
                        .font(.title2.weight(.semibold))
                    Text("Troque de janela pelo teclado e esconda os apps que só atrapalham. São poucos passos.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(spacing: 10) {
                WelcomeStep(
                    number: 1,
                    done: true,
                    title: "Ache o Tern na barra de menus",
                    showsMenuBarIcon: true,
                    detail: "Ele não aparece no Dock. Procure o ícone de duas janelas no canto superior direito da tela."
                ) {
                    EmptyView()
                }

                WelcomeStep(
                    number: 2,
                    done: model.isTrusted,
                    title: "Permita Acessibilidade",
                    badge: "Obrigatório",
                    detail: "O macOS só deixa o Tern listar e trocar janelas com essa permissão. Ligue a chave do Tern na lista e volte aqui."
                ) {
                    if !model.isTrusted {
                        Button("Abrir Ajustes do Sistema") {
                            AccessibilityPermission.promptIfNeeded()
                            AccessibilityPermission.openSystemSettings()
                        }
                    }
                }

                WelcomeStep(
                    number: 3,
                    done: model.canCaptureScreen,
                    title: "Ative as prévias",
                    badge: "Opcional",
                    detail: "Com Gravação da Tela, cada card mostra uma miniatura da janela. O Tern não grava nada."
                ) {
                    if !model.canCaptureScreen {
                        Button("Pedir permissão") {
                            ScreenCapturePermission.request {
                                model.canCaptureScreen = ScreenCapturePermission.isTrusted
                            }
                        }
                    }
                }

                WelcomeStep(
                    number: 4,
                    done: triedSwitcher,
                    title: "Experimente",
                    detail: "Aperte \(model.hotkey.displayString) para abrir o seletor. Continue segurando o modificador para avançar e solte para focar."
                ) {
                    EmptyView()
                }
                .opacity(model.isTrusted ? 1 : 0.5)
            }

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Toggle("Abrir o Tern ao iniciar sessão", isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                ))
                if model.launchAtLoginNeedsApproval {
                    HStack(spacing: 8) {
                        Text("Falta aprovar o Tern em Itens de Início.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                        Button("Abrir Itens de Início") {
                            LaunchAtLogin.openSystemSettings()
                        }
                        .controlSize(.small)
                    }
                }
            }

            HStack {
                Spacer()
                Button("Começar") {
                    model.closeWelcome()
                }
                .keyboardShortcut(.defaultAction)
                .controlSize(.large)
            }
        }
        .padding(28)
        .frame(width: 560)
        .onChange(of: model.isSwitcherVisible) { visible in
            if visible { triedSwitcher = true }
        }
        .onAppear {
            model.refreshLaunchAtLogin()
        }
    }
}

private struct WelcomeStep<Accessory: View>: View {
    let number: Int
    let done: Bool
    let title: LocalizedStringKey
    var badge: LocalizedStringKey?
    var showsMenuBarIcon = false
    let detail: LocalizedStringKey
    @ViewBuilder let accessory: () -> Accessory

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(done ? Color.green : Color.secondary.opacity(0.18))
                    .frame(width: 26, height: 26)
                if done {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                } else {
                    Text(verbatim: "\(number)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.headline)
                    if showsMenuBarIcon {
                        Image("MenuBarIcon")
                            .foregroundStyle(.tint)
                    }
                    if let badge {
                        Text(badge)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.secondary.opacity(0.15)))
                    }
                }
                Text(detail)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                accessory()
                    .padding(.top, 6)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.secondary.opacity(0.07)))
    }
}
