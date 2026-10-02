import AppKit
import CoreGraphics

struct WindowEnumerator {
    func enumerate(exclusions: PersistedExclusions, ignoringBundleID: String?) -> [WindowInfo] {
        let options: CGWindowListOption = [.optionAll, .excludeDesktopElements]
        guard let raw = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var seen = Set<CGWindowID>()
        var result: [WindowInfo] = []

        for entry in raw {
            guard let rawID = Self.intValue(entry[kCGWindowNumber as String]) else { continue }
            let windowID = CGWindowID(UInt32(clamping: rawID))
            guard seen.insert(windowID).inserted else { continue }
            guard let layer = Self.intValue(entry[kCGWindowLayer as String]), layer == 0 else { continue }
            guard let pidNumber = Self.intValue(entry[kCGWindowOwnerPID as String]) else { continue }
            let pid = pid_t(Int32(clamping: pidNumber))
            guard let app = NSRunningApplication(processIdentifier: pid),
                  app.activationPolicy == .regular,
                  let bundleID = app.bundleIdentifier else { continue }
            if let ignoringBundleID, bundleID == ignoringBundleID { continue }

            let title = entry[kCGWindowName as String] as? String ?? ""
            if exclusions.hides(bundleID: bundleID, title: title) { continue }

            let bounds = Self.bounds(from: entry)
            let onscreen = Self.boolValue(entry[kCGWindowIsOnscreen as String])
            if onscreen && bounds.width > 0 && bounds.height > 0 && (bounds.width < 50 || bounds.height < 50) {
                continue
            }

            let appName = app.localizedName
                ?? (entry[kCGWindowOwnerName as String] as? String)
                ?? bundleID

            result.append(
                WindowInfo(
                    windowID: windowID,
                    ownerPID: pid,
                    bundleID: bundleID,
                    appName: appName,
                    title: title,
                    bounds: bounds,
                    isOnscreen: onscreen
                )
            )
        }

        return result
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

    private static func bounds(from entry: [String: Any]) -> CGRect {
        guard let dict = entry[kCGWindowBounds as String] as? [String: Any] else {
            return .zero
        }
        let x = Self.cgFloat(dict["X"])
        let y = Self.cgFloat(dict["Y"])
        let width = Self.cgFloat(dict["Width"])
        let height = Self.cgFloat(dict["Height"])
        return CGRect(x: x, y: y, width: width, height: height)
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
