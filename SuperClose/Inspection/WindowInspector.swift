// WindowInspector.swift
// Walks `NSWorkspace.shared.runningApplications`, filters out anything
// `SuperCloseRules` says to skip, and counts each remaining app's open vs
// hidden windows. Prefers the Accessibility API (`AXUIElement` window list,
// minimized state, size filtering) and falls back to `CGWindowListCopyWindowInfo`
// when AX data isn't available. Produces the sorted `[AppCandidate]` array that
// drives both the review window and the CLI `--dump` output.

import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

struct AccessibilityWindow: Equatable {
    let isMinimized: Bool
}

final class WindowInspector {
    private let rules: SuperCloseRules
    private let currentPID: pid_t
    private let runningApplicationsProvider: () -> [NSRunningApplication]
    private let dockBundleIDsProvider: () -> Set<String>

    init(
        rules: SuperCloseRules = SuperCloseRules(),
        currentPID: pid_t = ProcessInfo.processInfo.processIdentifier,
        runningApplicationsProvider: @escaping () -> [NSRunningApplication] = { NSWorkspace.shared.runningApplications },
        dockBundleIDsProvider: @escaping () -> Set<String> = WindowInspector.loadDockBundleIDs
    ) {
        self.rules = rules
        self.currentPID = currentPID
        self.runningApplicationsProvider = runningApplicationsProvider
        self.dockBundleIDsProvider = dockBundleIDsProvider
    }

    func inspectCandidates() -> [AppCandidate] {
        let cgWindowCounts = loadCGWindowCounts()
        let dockBundleIDs = dockBundleIDsProvider()

        let apps = runningApplicationsProvider()
            .filter { !$0.isTerminated && $0.processIdentifier != currentPID && $0.activationPolicy != .prohibited }

        var candidates: [AppCandidate] = []

        for app in apps {
            let bundleIdentifier = app.bundleIdentifier ?? ""
            let displayName = rules.preferredDisplayName(
                localizedName: app.localizedName,
                bundleIdentifier: bundleIdentifier
            )

            if rules.shouldSkip(
                displayName: displayName,
                bundleIdentifier: bundleIdentifier,
                bundlePath: app.bundleURL?.path
            ) {
                continue
            }

            let descriptor = AppDescriptor(
                displayName: displayName,
                bundleIdentifier: bundleIdentifier,
                bundlePath: app.bundleURL?.path,
                activationPolicy: app.activationPolicy,
                isFinder: displayName == "Finder" || bundleIdentifier == "com.apple.finder",
                isDockPinned: dockBundleIDs.contains(bundleIdentifier),
                hasUIKitStyleBundleMetadata: hasUIKitStyleBundleMetadata(app)
            )

            let windowCounts = Self.classifyWindowCounts(
                appIsHidden: app.isHidden,
                accessibilityWindows: accessibilityWindows(for: app),
                cgWindowCount: cgWindowCounts[app.processIdentifier] ?? 0
            )

            if windowCounts.total == 0 {
                continue
            }

            candidates.append(
                AppCandidate(
                    app: app,
                    descriptor: descriptor,
                    windowCounts: windowCounts,
                    recommendedAction: rules.recommendedAction(for: descriptor)
                )
            )
        }

        return candidates.sorted { lhs, rhs in
            if lhs.recommendedAction != rhs.recommendedAction {
                return lhs.recommendedAction.rawValue > rhs.recommendedAction.rawValue
            }

            return lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    static func classifyWindowCounts(
        appIsHidden: Bool,
        accessibilityWindows: [AccessibilityWindow],
        cgWindowCount: Int
    ) -> WindowCounts {
        if !accessibilityWindows.isEmpty {
            if appIsHidden {
                return WindowCounts(open: 0, hidden: accessibilityWindows.count)
            }

            let hiddenCount = accessibilityWindows.filter(\.isMinimized).count
            return WindowCounts(open: accessibilityWindows.count - hiddenCount, hidden: hiddenCount)
        }

        if appIsHidden {
            return WindowCounts(open: 0, hidden: cgWindowCount)
        }

        return WindowCounts(open: cgWindowCount, hidden: 0)
    }

    private func accessibilityWindows(for app: NSRunningApplication) -> [AccessibilityWindow] {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)
        var rawValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &rawValue)

        guard result == .success, let windows = rawValue as? [AXUIElement] else {
            return []
        }

        return windows.compactMap(makeAccessibilityWindow(_:))
    }

    private func makeAccessibilityWindow(_ element: AXUIElement) -> AccessibilityWindow? {
        guard stringAttribute(kAXRoleAttribute, from: element) == kAXWindowRole as String else {
            return nil
        }

        if let size = sizeAttribute(kAXSizeAttribute, from: element),
           size.width < 80 || size.height < 60 {
            return nil
        }

        return AccessibilityWindow(isMinimized: boolAttribute(kAXMinimizedAttribute, from: element) ?? false)
    }

    private func hasUIKitStyleBundleMetadata(_ app: NSRunningApplication) -> Bool {
        guard let bundleURL = app.bundleURL else {
            return false
        }

        let infoPlistURL = bundleURL.appendingPathComponent("Contents/Info.plist")
        guard let info = NSDictionary(contentsOf: infoPlistURL) as? [String: Any] else {
            return false
        }

        return info["UISupportedInterfaceOrientations~iphone"] != nil
            || info["UISupportedInterfaceOrientations~ipad"] != nil
    }

    private static func loadDockBundleIDs() -> Set<String> {
        guard let defaults = UserDefaults(suiteName: "com.apple.dock"),
              let items = defaults.array(forKey: "persistent-apps") as? [[String: Any]] else {
            return []
        }

        return Set(
            items.compactMap { item in
                (item["tile-data"] as? [String: Any])?["bundle-identifier"] as? String
            }
        )
    }

    private func stringAttribute(_ key: String, from element: AXUIElement) -> String? {
        var rawValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, key as CFString, &rawValue)
        guard result == .success else {
            return nil
        }
        return rawValue as? String
    }

    private func boolAttribute(_ key: String, from element: AXUIElement) -> Bool? {
        var rawValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, key as CFString, &rawValue)
        guard result == .success else {
            return nil
        }
        return rawValue as? Bool
    }

    private func sizeAttribute(_ key: String, from element: AXUIElement) -> CGSize? {
        var rawValue: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, key as CFString, &rawValue)
        guard result == .success, let value = rawValue else {
            return nil
        }

        guard CFGetTypeID(value) == AXValueGetTypeID() else {
            return nil
        }

        let axValue = unsafeBitCast(value, to: AXValue.self)

        guard AXValueGetType(axValue) == .cgSize else {
            return nil
        }

        var size = CGSize.zero
        guard AXValueGetValue(axValue, .cgSize, &size) else {
            return nil
        }

        return size
    }

    private func loadCGWindowCounts() -> [pid_t: Int] {
        guard let rawWindows = CGWindowListCopyWindowInfo([.optionAll], kCGNullWindowID) as? [[String: Any]] else {
            return [:]
        }

        var counts: [pid_t: Int] = [:]

        for window in rawWindows {
            guard let pid = window[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }

            guard let ownerName = window[kCGWindowOwnerName as String] as? String else {
                continue
            }

            if rules.configuration.skipNames.contains(ownerName) {
                continue
            }

            let layer = window[kCGWindowLayer as String] as? Int ?? -1
            if layer != 0 {
                continue
            }

            let alpha = window[kCGWindowAlpha as String] as? Double ?? 1.0
            if alpha <= 0.0 {
                continue
            }

            let bounds = window[kCGWindowBounds as String] as? [String: Any] ?? [:]
            let width = bounds["Width"] as? Double ?? 0
            let height = bounds["Height"] as? Double ?? 0
            if width < 80 || height < 60 {
                continue
            }

            counts[pid, default: 0] += 1
        }

        return counts
    }
}
