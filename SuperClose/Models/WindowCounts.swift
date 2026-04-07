// WindowCounts.swift
// Tally of how many windows an app currently has open versus hidden/minimized.
// Produced by `WindowInspector` and used by both the UI row detail text and the
// CLI `--dump` output.

import Foundation

struct WindowCounts: Equatable {
    let open: Int
    let hidden: Int

    var total: Int {
        open + hidden
    }
}

