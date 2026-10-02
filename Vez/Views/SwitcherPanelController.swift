import AppKit
import SwiftUI

@MainActor
final class SwitcherPanelController {
    private weak var model: AppModel?
    private var panel: NSPanel?
    private var localMonitor: Any?
    private var globalKeyMonitor: Any?
    private var globalFlagsMonitor: Any?
    private var mouseMonitor: Any?

    func attach(model: AppModel) {
        self.model = model
    }

    func show() {
        guard let model else { return }
        let panel = makePanelIfNeeded(model: model)
        resize(panel, model: model)
        position(panel)
        panel.orderFrontRegardless()
        panel.makeKey()
        installMonitors()
    }

    func hide() {
        removeMonitors()
        panel?.orderOut(nil)
    }

    func updateFrameIfVisible() {
        guard let panel, let model, panel.isVisible else { return }
        resize(panel, model: model)
        position(panel)
    }

    private func makePanelIfNeeded(model: AppModel) -> NSPanel {
        if let panel {
            return panel
        }

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 320),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isMovableByWindowBackground = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.animationBehavior = .utilityWindow
        panel.title = "Vez"
        panel.identifier = NSUserInterfaceItemIdentifier("vez.switcher")

        let root = SwitcherView()
            .environmentObject(model)
        let hosting = NSHostingView(rootView: root)
        hosting.autoresizingMask = [.width, .height]
        hosting.frame = panel.contentView?.bounds ?? panel.frame
        panel.contentView = hosting
        self.panel = panel
        return panel
    }

    private func resize(_ panel: NSPanel, model: AppModel) {
        let count = max(model.windows.count, 1)
        let width = min(CGFloat(count) * 240 + 56, 1100)
        let height: CGFloat = model.isTrusted ? 380 : 280
        panel.setContentSize(NSSize(width: width, height: height))
    }

    private func position(_ panel: NSPanel) {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let origin = NSPoint(
            x: visible.midX - size.width / 2,
            y: visible.midY - size.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    private func installMonitors() {
        removeMonitors()
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown, .flagsChanged]) { event in
            AppModel.handleSwitcherEventAssumingMain(event) ? nil : event
        }
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            _ = AppModel.handleSwitcherEventAssumingMain(event)
        }
        globalFlagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { event in
            _ = AppModel.handleSwitcherEventAssumingMain(event)
        }
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Self.handleOutsideClickAssumingMain(controller: self, event: event)
        }
    }

    private nonisolated static func handleOutsideClickAssumingMain(
        controller: SwitcherPanelController?,
        event: NSEvent
    ) {
        MainActor.assumeIsolated {
            guard let controller, let panel = controller.panel else { return }
            if event.window != panel {
                controller.model?.dismissSwitcher()
            }
        }
    }

    private func removeMonitors() {
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
        if let globalKeyMonitor {
            NSEvent.removeMonitor(globalKeyMonitor)
            self.globalKeyMonitor = nil
        }
        if let globalFlagsMonitor {
            NSEvent.removeMonitor(globalFlagsMonitor)
            self.globalFlagsMonitor = nil
        }
        if let mouseMonitor {
            NSEvent.removeMonitor(mouseMonitor)
            self.mouseMonitor = nil
        }
    }
}
