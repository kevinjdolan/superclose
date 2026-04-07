// AppStrings.swift
// All user-facing strings used by the app and CLI live here: window titles,
// alert copy, action labels, the keyboard legend, and helper formatters for the
// row detail line and Run button title. Centralizing them keeps copy edits in
// one place and out of the view code.

import Foundation

enum AppStrings {
    static let appName = "SuperClose"
    static let executableName = "superclose"

    static let emptyStateTitle = "SuperClose"
    static let emptyStateMessage = "No qualifying app windows are open right now."
    static let finishedWithNotesTitle = "SuperClose finished with notes"

    static let permissionTitle = "Accessibility permission is required"
    static let permissionMessage = "SuperClose needs Accessibility access so it can see app windows and manage hiding, quitting, and force-quitting for you. macOS should open the permission pane now."
    static let openSettingsButtonTitle = "Open Settings"
    static let cancelButtonTitle = "Cancel"
    static let okayButtonTitle = "OK"

    static let windowTitle = "SuperClose"
    static let windowHeader = "Currently Open Applications"
    static let actionLabels = ["Ignore", "Hide", "Quit", "Kill"]
    static let actionTooltip = "Up and down choose rows. Left and right change the action. A, S, D, and F choose Ignore, Hide, Quit, and Kill."

    static let legendEntries: [(key: String, description: String)] = [
        ("↑/↓", "select"),
        ("←/→", "change action"),
        ("A", "ignore"),
        ("S", "hide"),
        ("D", "quit"),
        ("F", "kill"),
        ("Enter", "run"),
    ]

    static func detailText(for windowCounts: WindowCounts) -> String {
        "\(windowCounts.open) open window\(windowCounts.open == 1 ? "" : "s") • \(windowCounts.hidden) hidden"
    }

    static func runButtonTitle(quitCount: Int, hideCount: Int, killCount: Int) -> String {
        "Quit \(quitCount) Apps, Hide \(hideCount) Apps, Kill \(killCount) Apps"
    }
}

