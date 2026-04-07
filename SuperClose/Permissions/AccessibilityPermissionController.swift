// AccessibilityPermissionController.swift
// Gates SuperClose on macOS Accessibility permission. On launch, checks
// `AXIsProcessTrusted()`; if not trusted, triggers the system prompt, shows an
// explanatory alert, and offers to open System Settings → Privacy &
// Security → Accessibility. Returns false until the user grants access and
// relaunches the app.

import AppKit
import ApplicationServices
import Foundation

final class AccessibilityPermissionController {
    func ensureTrusted() -> Bool {
        if AXIsProcessTrusted() {
            return true
        }

        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = AppStrings.permissionTitle
        alert.informativeText = AppStrings.permissionMessage
        alert.addButton(withTitle: AppStrings.openSettingsButtonTitle)
        alert.addButton(withTitle: AppStrings.cancelButtonTitle)

        let response = alert.runModal()
        if response == .alertFirstButtonReturn,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }

        return false
    }
}

