// FlippedView.swift
// Trivial NSView subclass that returns `isFlipped == true` so child views lay
// out top-down. Used as the document view inside the review window's
// NSScrollView so the row stack reads naturally from the top.

import AppKit

final class FlippedView: NSView {
    override var isFlipped: Bool {
        true
    }
}

