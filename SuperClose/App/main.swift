// main.swift
// Process entry point. Parses CLI options, short-circuits for `--help`, ensures
// Accessibility permission via `AccessibilityPermissionController`, runs
// `WindowInspector` to gather candidate apps, then either prints the
// `--dump` summary or hands the candidates to `SuperCloseAppDelegate` and
// starts the AppKit run loop.

import AppKit
import Foundation

let options = CommandLineOptions()

if options.showsHelp {
    print(CommandLineReporter.usageText)
    exit(EXIT_SUCCESS)
}

let application = NSApplication.shared
application.setActivationPolicy(.regular)

let permissionController = AccessibilityPermissionController()
guard permissionController.ensureTrusted() else {
    exit(EXIT_FAILURE)
}

let inspector = WindowInspector()
let candidates = inspector.inspectCandidates()

if options.dumpsCandidates {
    let dumpText = CommandLineReporter.dumpText(for: candidates)
    if !dumpText.isEmpty {
        print(dumpText)
    }
    exit(EXIT_SUCCESS)
}

application.activate(ignoringOtherApps: true)

let delegate = SuperCloseAppDelegate(candidates: candidates)
application.delegate = delegate
application.run()

