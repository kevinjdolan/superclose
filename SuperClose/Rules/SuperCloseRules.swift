// SuperCloseRules.swift
// The brain behind which apps SuperClose shows and what default action each
// gets. `SuperCloseConfiguration` holds the curated allow/skip lists and bundle
// id → preferred-name overrides; `SuperCloseRules` consults that configuration
// to filter out system UI agents, pick a display name, and recommend Hide/Quit
// based on activation policy, dock pinning, and other heuristics.

import AppKit
import Foundation

struct SuperCloseConfiguration {
    let skipBundleIDs: Set<String>
    let skipNames: Set<String>
    let closePreferredBundleIDs: Set<String>
    let closePreferredNames: Set<String>
    let preferredNamesByBundleID: [String: String]

    static let `default` = SuperCloseConfiguration(
        skipBundleIDs: [
            "com.apple.controlcenter",
            "com.apple.coreservices.uiagent",
            "com.apple.dock",
            "com.apple.findmy.findmylocateagent",
            "com.apple.loginwindow",
            "com.apple.notificationcenterui",
            "com.apple.Spotlight",
            "com.apple.systemuiserver",
            "com.apple.universalcontrol",
            "com.apple.ViewBridgeAuxiliary",
            "com.apple.wallpaper",
            "com.apple.WindowManager",
        ],
        skipNames: [
            "Accessibility",
            "AutoFill",
            "Control Center",
            "CoreLocationAgent",
            "CursorUIViewService",
            "Dock",
            "Karabiner-NotificationWindow",
            "loginwindow",
            "Notification Center",
            "nsattributedstringagent",
            "Open and Save Panel Service",
            "Spotlight",
            "SystemUIServer",
            "talagentd",
            "TextInputSwitcher",
            "Universal Control",
            "ViewBridgeAuxiliary",
            "Wallpaper",
            "WindowManager",
        ],
        closePreferredBundleIDs: [
            "com.1password.1password",
            "com.anthropic.claudefordesktop",
            "com.docker.docker",
            "com.knollsoft.Rectangle",
            "org.pqrs.Karabiner-Elements.Settings",
            "org.pqrs.Karabiner-Menu",
        ],
        closePreferredNames: [
            "1Password",
            "Claude",
            "Docker",
            "Docker Desktop",
            "Karabiner-Elements",
            "Karabiner-Menu",
            "Rectangle",
        ],
        preferredNamesByBundleID: [
            "com.googlecode.iterm2": "iTerm",
            "com.microsoft.VSCode": "Visual Studio Code",
        ]
    )
}

struct SuperCloseRules {
    let configuration: SuperCloseConfiguration

    init(configuration: SuperCloseConfiguration = .default) {
        self.configuration = configuration
    }

    func preferredDisplayName(localizedName: String?, bundleIdentifier: String) -> String {
        if let preferredName = configuration.preferredNamesByBundleID[bundleIdentifier] {
            return preferredName
        }

        if let localizedName, !localizedName.isEmpty {
            return localizedName
        }

        return bundleIdentifier
    }

    func shouldSkip(displayName: String, bundleIdentifier: String, bundlePath: String?) -> Bool {
        if configuration.skipNames.contains(displayName) {
            return true
        }

        if !bundleIdentifier.isEmpty, configuration.skipBundleIDs.contains(bundleIdentifier) {
            return true
        }

        if bundleIdentifier.isEmpty, displayName != "Finder" {
            return true
        }

        guard let bundlePath else {
            return false
        }

        if bundlePath.contains("/XPCServices/") {
            return true
        }

        if bundlePath.contains("/Library/CoreServices/"), displayName != "Finder" {
            return true
        }

        return false
    }

    func recommendedAction(for descriptor: AppDescriptor) -> SelectedAction {
        if descriptor.isFinder {
            return .hide
        }

        if configuration.closePreferredBundleIDs.contains(descriptor.bundleIdentifier)
            || configuration.closePreferredNames.contains(descriptor.displayName) {
            return .hide
        }

        if descriptor.activationPolicy == .accessory {
            return .hide
        }

        if descriptor.hasUIKitStyleBundleMetadata {
            return .hide
        }

        if descriptor.isDockPinned {
            return .quit
        }

        return .quit
    }
}

