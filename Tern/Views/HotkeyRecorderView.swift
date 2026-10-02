import AppKit
import Carbon
import SwiftUI

struct HotkeyRecorderView: View {
    let chord: HotkeyChord
    let onChange: (HotkeyChord) -> Void

    @State private var isRecording = false
    @State private var message: String?

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Button {
                beginRecording()
            } label: {
                Text(isRecording ? String(localized: "Aguardando tecla…") : chord.displayString)
                    .font(.system(.body, design: .rounded).monospaced())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isRecording ? Color.accentColor.opacity(0.2) : Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isRecording ? Color.accentColor : Color.primary.opacity(0.12))
                    )
            }
            .buttonStyle(.plain)
            .background(
                HotkeyCatcher(isRecording: $isRecording, onEvent: handle)
                    .frame(width: 0, height: 0)
            )
            .onDisappear {
                if isRecording {
                    finishRecording()
                }
            }
            if let message {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private func beginRecording() {
        message = nil
        isRecording = true
        AppModel.shared.hotkeys.unregister()
    }

    private func finishRecording() {
        isRecording = false
        AppModel.shared.hotkeys.register(AppModel.shared.hotkey)
    }

    private func handle(_ event: NSEvent) {
        guard isRecording else { return }
        if event.type == .keyDown && event.keyCode == UInt16(kVK_Escape) {
            finishRecording()
            return
        }
        guard event.type == .keyDown else { return }
        guard let recorded = HotkeyChord.from(event: event) else {
            message = String(localized: "Inclua pelo menos um modificador (⌥, ⌃, ⇧ ou ⌘).")
            return
        }
        if recorded.isReservedSystemSwitcher {
            message = String(localized: "⌘⇥ é do seletor de apps do macOS. Escolha outro atalho, como ⌥⇥.")
            return
        }
        message = nil
        onChange(recorded)
        finishRecording()
    }
}

private struct HotkeyCatcher: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onEvent: (NSEvent) -> Void

    func makeNSView(context: Context) -> CatcherView {
        let view = CatcherView()
        view.onEvent = onEvent
        view.isRecording = isRecording
        return view
    }

    func updateNSView(_ nsView: CatcherView, context: Context) {
        nsView.onEvent = onEvent
        nsView.isRecording = isRecording
        if isRecording {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class CatcherView: NSView {
        var isRecording = false
        var onEvent: ((NSEvent) -> Void)?
        private var monitor: Any?

        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            install()
        }

        override func keyDown(with event: NSEvent) {
            if isRecording {
                return
            }
            super.keyDown(with: event)
        }

        private func install() {
            guard monitor == nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                guard let self, self.isRecording else { return event }
                self.onEvent?(event)
                return nil
            }
        }

        deinit {
            if let monitor {
                NSEvent.removeMonitor(monitor)
            }
        }
    }
}
