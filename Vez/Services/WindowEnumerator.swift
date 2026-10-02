import AppKit
import ApplicationServices
import CoreGraphics

@_silgen_name("_AXUIElementGetWindow")
func AXPrivateGetWindow(_ element: AXUIElement, _ identifierOut: UnsafeMutablePointer<CGWindowID>) -> AXError

enum AccessibilityWindows {
    static func copy(_ element: AXUIElement, _ attribute: String) -> AnyObject? {
        var raw: AnyObject?
        let error = AXUIElementCopyAttributeValue(element, attribute as CFString, &raw)
        return error == .success ? raw : nil
    }

    static func stringValue(_ element: AXUIElement, _ attribute: String) -> String {
        copy(element, attribute) as? String ?? ""
    }

    static func boolValue(_ element: AXUIElement, _ attribute: String) -> Bool {
        if let flag = copy(element, attribute) as? Bool { return flag }
        if let number = copy(element, attribute) as? NSNumber { return number.boolValue }
        return false
    }

    static func windows(for pid: pid_t) -> [AXUIElement] {
        let app = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(app, 0.8)
        return copy(app, kAXWindowsAttribute as String) as? [AXUIElement] ?? []
    }

    static func windowID(_ element: AXUIElement) -> CGWindowID? {
        let raw = copy(element, "AXWindowNumber")
        if let number = raw as? NSNumber {
            let identifier = CGWindowID(truncating: number)
            if identifier != kCGNullWindowID { return identifier }
        }
        if let value = raw as? Int {
            let identifier = CGWindowID(value)
            if identifier != kCGNullWindowID { return identifier }
        }

        var identifier = kCGNullWindowID
        if AXPrivateGetWindow(element, &identifier) == .success, identifier != kCGNullWindowID {
            return identifier
        }
        return nil
    }

    static func title(_ element: AXUIElement) -> String {
        stringValue(element, kAXTitleAttribute as String)
    }

    static func isMinimized(_ element: AXUIElement) -> Bool {
        boolValue(element, kAXMinimizedAttribute as String)
    }

    static func frame(_ element: AXUIElement) -> CGRect? {
        guard let position = copy(element, kAXPositionAttribute as String),
              let sizeValue = copy(element, kAXSizeAttribute as String) else {
            return nil
        }
        var origin = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &origin),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &size),
              size.width > 0,
              size.height > 0 else {
            return nil
        }
        return CGRect(origin: origin, size: size)
    }

    static func isSwitcherWindow(_ element: AXUIElement) -> Bool {
        let role = stringValue(element, kAXRoleAttribute as String)
        guard role == "AXWindow" || role == "AXSheet" else { return false }
        switch stringValue(element, kAXSubroleAttribute as String) {
        case "AXStandardWindow", "AXDialog", "AXSystemDialog", "AXFloatingWindow", "AXUnknown", "":
            return true
        default:
            return false
        }
    }
}

struct WindowEnumerator {
    private struct CGRecord {
        var windowID: CGWindowID
        var pid: pid_t
        var title: String
        var bounds: CGRect
        var onscreen: Bool
        var alpha: CGFloat
        var order: Int
        var bundleID: String
        var appName: String
    }

    func enumerate(exclusions: PersistedExclusions, ignoringBundleID: String?) -> [WindowInfo] {
        let catalog = loadCatalog(ignoringBundleID: ignoringBundleID)
        var usedIDs = Set<CGWindowID>()
        var result: [WindowInfo] = []
        var pidsCoveredByAX = Set<pid_t>()

        if AccessibilityPermission.isTrusted {
            for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
                guard let bundleID = app.bundleIdentifier else { continue }
                if let ignoringBundleID, bundleID == ignoringBundleID { continue }

                let pid = app.processIdentifier
                let axWindows = AccessibilityWindows.windows(for: pid)
                var addedForPID = 0

                for axWindow in axWindows where AccessibilityWindows.isSwitcherWindow(axWindow) {
                    let record = matchRecord(axWindow: axWindow, pid: pid, catalog: catalog, usedIDs: usedIDs)
                    guard let windowID = record?.windowID ?? AccessibilityWindows.windowID(axWindow) else {
                        continue
                    }
                    guard usedIDs.insert(windowID).inserted else { continue }

                    let title = preferredTitle(ax: AccessibilityWindows.title(axWindow), cg: record?.title)
                    if exclusions.hides(bundleID: bundleID, title: title) { continue }

                    let minimized = AccessibilityWindows.isMinimized(axWindow)
                    result.append(
                        WindowInfo(
                            windowID: windowID,
                            ownerPID: pid,
                            bundleID: bundleID,
                            appName: app.localizedName ?? record?.appName ?? bundleID,
                            title: title,
                            bounds: record?.bounds ?? AccessibilityWindows.frame(axWindow) ?? .zero,
                            isOnscreen: record?.onscreen ?? !minimized,
                            isMinimized: minimized
                        )
                    )
                    addedForPID += 1
                }

                if addedForPID > 0 {
                    pidsCoveredByAX.insert(pid)
                }
            }
        }

        for record in catalog.values.sorted(by: { $0.order < $1.order }) {
            if pidsCoveredByAX.contains(record.pid) { continue }
            guard usedIDs.insert(record.windowID).inserted else { continue }
            guard isPlausibleWindow(record) else { continue }
            if exclusions.hides(bundleID: record.bundleID, title: record.title) { continue }
            result.append(
                WindowInfo(
                    windowID: record.windowID,
                    ownerPID: record.pid,
                    bundleID: record.bundleID,
                    appName: record.appName,
                    title: record.title,
                    bounds: record.bounds,
                    isOnscreen: record.onscreen,
                    isMinimized: !record.onscreen
                )
            )
        }

        return result.sorted { lhs, rhs in
            let left = catalog[lhs.windowID]?.order ?? Int.max
            let right = catalog[rhs.windowID]?.order ?? Int.max
            return left < right
        }
    }

    func runningRegularApps(ignoringBundleID: String?) -> [RunningAppInfo] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .compactMap { app in
                guard let bundleID = app.bundleIdentifier else { return nil }
                if let ignoringBundleID, bundleID == ignoringBundleID { return nil }
                return RunningAppInfo(
                    bundleID: bundleID,
                    name: app.localizedName ?? bundleID,
                    icon: app.icon ?? AppIcon.image(bundleID: bundleID, pid: app.processIdentifier)
                )
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func matchRecord(
        axWindow: AXUIElement,
        pid: pid_t,
        catalog: [CGWindowID: CGRecord],
        usedIDs: Set<CGWindowID>
    ) -> CGRecord? {
        if let identifier = AccessibilityWindows.windowID(axWindow),
           let record = catalog[identifier],
           !usedIDs.contains(identifier) {
            return record
        }

        let candidates = catalog.values.filter { $0.pid == pid && !usedIDs.contains($0.windowID) }
        guard !candidates.isEmpty else { return nil }

        let title = AccessibilityWindows.title(axWindow).trimmingCharacters(in: .whitespacesAndNewlines)
        let frame = AccessibilityWindows.frame(axWindow)
        let titled = title.isEmpty ? [] : candidates.filter { $0.title == title }

        if titled.count == 1 {
            return titled[0]
        }
        if let frame, let best = closest(titled.isEmpty ? Array(candidates) : titled, to: frame) {
            if frameDistance(best.bounds, frame) < 140 {
                return best
            }
        }
        if candidates.count == 1 {
            return candidates[0]
        }
        return nil
    }

    private func closest(_ records: [CGRecord], to frame: CGRect) -> CGRecord? {
        records.min { lhs, rhs in
            frameDistance(lhs.bounds, frame) < frameDistance(rhs.bounds, frame)
        }
    }

    private func frameDistance(_ lhs: CGRect, _ rhs: CGRect) -> CGFloat {
        let dx = lhs.midX - rhs.midX
        let dy = lhs.midY - rhs.midY
        let dw = lhs.width - rhs.width
        let dh = lhs.height - rhs.height
        return (dx * dx + dy * dy + dw * dw + dh * dh).squareRoot()
    }

    private func loadCatalog(ignoringBundleID: String?) -> [CGWindowID: CGRecord] {
        let options: CGWindowListOption = [.optionAll, .excludeDesktopElements]
        guard let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return [:]
        }

        var catalog: [CGWindowID: CGRecord] = [:]
        for (order, entry) in raw.enumerated() {
            guard let layer = Self.intValue(entry[kCGWindowLayer as String]), layer == 0 else { continue }
            guard let rawID = Self.intValue(entry[kCGWindowNumber as String]) else { continue }
            let windowID = CGWindowID(UInt32(clamping: rawID))
            guard catalog[windowID] == nil else { continue }
            guard let pidNumber = Self.intValue(entry[kCGWindowOwnerPID as String]) else { continue }
            let pid = pid_t(Int32(clamping: pidNumber))
            guard let app = NSRunningApplication(processIdentifier: pid),
                  app.activationPolicy == .regular,
                  let bundleID = app.bundleIdentifier else { continue }
            if let ignoringBundleID, bundleID == ignoringBundleID { continue }

            catalog[windowID] = CGRecord(
                windowID: windowID,
                pid: pid,
                title: entry[kCGWindowName as String] as? String ?? "",
                bounds: Self.bounds(from: entry),
                onscreen: Self.boolValue(entry[kCGWindowIsOnscreen as String]),
                alpha: Self.cgFloat(entry[kCGWindowAlpha as String]),
                order: order,
                bundleID: bundleID,
                appName: app.localizedName
                    ?? (entry[kCGWindowOwnerName as String] as? String)
                    ?? bundleID
            )
        }
        return catalog
    }

    private func isPlausibleWindow(_ record: CGRecord) -> Bool {
        if record.alpha <= 0.05 { return false }
        if record.bounds.width < 80 || record.bounds.height < 80 { return false }
        let titled = !record.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if record.onscreen {
            return titled || record.bounds.height >= 160
        }
        return titled && record.bounds.width >= 240 && record.bounds.height >= 160
    }

    private func preferredTitle(ax: String, cg: String?) -> String {
        let axTitle = ax.trimmingCharacters(in: .whitespacesAndNewlines)
        if !axTitle.isEmpty { return axTitle }
        return cg ?? ""
    }

    private static func bounds(from entry: [String: Any]) -> CGRect {
        guard let dict = entry[kCGWindowBounds as String] as? [String: Any] else {
            return .zero
        }
        return CGRect(
            x: Self.cgFloat(dict["X"]),
            y: Self.cgFloat(dict["Y"]),
            width: Self.cgFloat(dict["Width"]),
            height: Self.cgFloat(dict["Height"])
        )
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let number = value as? Int { return number }
        if let number = value as? NSNumber { return number.intValue }
        return nil
    }

    private static func boolValue(_ value: Any?) -> Bool {
        if let flag = value as? Bool { return flag }
        if let number = value as? NSNumber { return number.boolValue }
        return false
    }

    private static func cgFloat(_ value: Any?) -> CGFloat {
        if let number = value as? NSNumber {
            return CGFloat(truncating: number)
        }
        if let double = value as? Double {
            return CGFloat(double)
        }
        return 0
    }
}
