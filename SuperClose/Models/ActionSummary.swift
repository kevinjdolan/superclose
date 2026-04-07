// ActionSummary.swift
// Result of running a batch of selected actions through `ActionRunner`. Holds
// human-readable success and failure messages so the app delegate can show a
// "finished with notes" alert if anything went sideways.

import Foundation

struct ActionSummary {
    let successes: [String]
    let failures: [String]
}

