// CommandLineReporter.swift
// Pure formatting helpers for the CLI surface: `usageText` for `--help` and
// `dumpText(for:)` for `--dump`, which prints a tab-separated summary of each
// candidate (name, open/hidden window counts, recommended action). Kept free of
// I/O so it can be unit tested.

import Foundation

enum CommandLineReporter {
    static var usageText: String {
        """
        \(AppStrings.executableName)

        Options:
          --dump    Print the current app candidates and their default actions.
          --help    Show this help.
        """
    }

    static func dumpText(for candidates: [AppCandidate]) -> String {
        candidates
            .map { candidate in
                let action = candidate.recommendedAction.title.lowercased()
                return "\(candidate.displayName)\topen=\(candidate.openWindowCount)\thidden=\(candidate.hiddenWindowCount)\t\(action)"
            }
            .joined(separator: "\n")
    }
}

