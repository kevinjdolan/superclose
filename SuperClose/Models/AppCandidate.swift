// AppCandidate.swift
// One row in the SuperClose review window: pairs the live `NSRunningApplication`
// with its `AppDescriptor`, current `WindowCounts`, and the recommended default
// `SelectedAction`. Convenience accessors expose the bits the UI and CLI need
// without reaching back through the descriptor each time.

import AppKit
import Foundation

struct AppCandidate {
    let app: NSRunningApplication
    let descriptor: AppDescriptor
    let windowCounts: WindowCounts
    let recommendedAction: SelectedAction

    var displayName: String {
        descriptor.displayName
    }

    var bundleIdentifier: String {
        descriptor.bundleIdentifier
    }

    var openWindowCount: Int {
        windowCounts.open
    }

    var hiddenWindowCount: Int {
        windowCounts.hidden
    }

    var totalWindowCount: Int {
        windowCounts.total
    }

    var allowsQuit: Bool {
        !descriptor.isFinder
    }
}

