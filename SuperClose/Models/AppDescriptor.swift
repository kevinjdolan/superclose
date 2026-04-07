// AppDescriptor.swift
// Plain-data snapshot of the metadata SuperClose cares about for a running app:
// display name, bundle id, activation policy, and a few flags (`isFinder`,
// `isDockPinned`, `hasUIKitStyleBundleMetadata`) that `SuperCloseRules` uses to
// pick a recommended default action.

import AppKit
import Foundation

struct AppDescriptor: Equatable {
    let displayName: String
    let bundleIdentifier: String
    let bundlePath: String?
    let activationPolicy: NSApplication.ActivationPolicy
    let isFinder: Bool
    let isDockPinned: Bool
    let hasUIKitStyleBundleMetadata: Bool
}

