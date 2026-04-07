// SelectedAction.swift
// The four actions a user can pick for an app row: Ignore, Hide, Quit, or Kill.
// Raw values match the order of the segmented control in `AppRowView`, and `title`
// supplies the user-facing label used in the UI and CLI dump output.

import Foundation

enum SelectedAction: Int, CaseIterable {
    case ignore = 0
    case hide = 1
    case quit = 2
    case kill = 3

    var title: String {
        switch self {
        case .ignore:
            return "Ignore"
        case .hide:
            return "Hide"
        case .quit:
            return "Quit"
        case .kill:
            return "Kill"
        }
    }
}

