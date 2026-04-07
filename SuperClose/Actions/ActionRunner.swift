// ActionRunner.swift
// Executes a batch of `(AppCandidate, SelectedAction)` pairs after the user
// hits Run. Walks each selection, dispatches to AppKit's hide / terminate /
// forceTerminate, briefly spins the run loop to confirm the app actually
// honored the request, and collects per-app success and failure messages into
// an `ActionSummary` for the delegate to surface.

import AppKit
import Foundation

final class ActionRunner {
    func run(_ selections: [(AppCandidate, SelectedAction)]) -> ActionSummary {
        var successes: [String] = []
        var failures: [String] = []

        for (candidate, action) in selections {
            switch action {
            case .ignore:
                continue
            case .hide:
                let result = hide(candidate.app, displayName: candidate.displayName)
                if result.success {
                    successes.append(result.message ?? "Hid \(candidate.displayName).")
                } else {
                    failures.append(result.message ?? "Could not hide \(candidate.displayName).")
                }
            case .quit:
                let result = quit(candidate.app, displayName: candidate.displayName)
                if result.success {
                    successes.append(result.message ?? "Requested quit for \(candidate.displayName).")
                } else {
                    failures.append(result.message ?? "Could not request quit for \(candidate.displayName).")
                }
            case .kill:
                let result = forceQuit(candidate.app, displayName: candidate.displayName)
                if result.success {
                    successes.append(result.message ?? "Force-quit \(candidate.displayName).")
                } else {
                    failures.append(result.message ?? "Could not force-quit \(candidate.displayName).")
                }
            }
        }

        return ActionSummary(successes: successes, failures: failures)
    }

    private func hide(_ app: NSRunningApplication, displayName: String) -> (success: Bool, message: String?) {
        if app.isHidden {
            return (true, "\(displayName) was already hidden.")
        }

        _ = app.hide()

        let deadline = Date().addingTimeInterval(1.0)
        while !app.isHidden && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        if app.isHidden {
            return (true, "Hid \(displayName).")
        }

        return (false, "Could not hide \(displayName).")
    }

    private func quit(_ app: NSRunningApplication, displayName: String) -> (success: Bool, message: String?) {
        let requested = app.terminate()
        if !requested {
            return (false, "Could not request quit for \(displayName).")
        }

        let deadline = Date().addingTimeInterval(1.5)
        while !app.isTerminated && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        if app.isTerminated {
            return (true, "Quit \(displayName).")
        }

        return (true, "\(displayName) may still be waiting on a save or confirmation dialog.")
    }

    private func forceQuit(_ app: NSRunningApplication, displayName: String) -> (success: Bool, message: String?) {
        let requested = app.forceTerminate()
        if !requested {
            return (false, "Could not force-quit \(displayName).")
        }

        let deadline = Date().addingTimeInterval(1.0)
        while !app.isTerminated && Date() < deadline {
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        if app.isTerminated {
            return (true, "Force-quit \(displayName).")
        }

        return (true, "Sent force-quit to \(displayName).")
    }
}

