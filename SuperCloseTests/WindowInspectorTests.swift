// WindowInspectorTests.swift
// Tests for `WindowInspector.classifyWindowCounts`, the pure function that
// reconciles AppKit's hidden flag, the Accessibility window list, and the
// CGWindow fallback count into a single `WindowCounts`. Covers the AX-available
// path, the hidden-app override, and the CGWindow fallback path.

import XCTest
@testable import SuperClose

final class WindowInspectorTests: XCTestCase {
    func testClassifyWindowCountsUsesAccessibilityWindowStateWhenAvailable() {
        let counts = WindowInspector.classifyWindowCounts(
            appIsHidden: false,
            accessibilityWindows: [
                AccessibilityWindow(isMinimized: false),
                AccessibilityWindow(isMinimized: true),
                AccessibilityWindow(isMinimized: false),
            ],
            cgWindowCount: 99
        )

        XCTAssertEqual(counts, WindowCounts(open: 2, hidden: 1))
    }

    func testClassifyWindowCountsTreatsHiddenAppAsAllHiddenWhenAccessibilityDataExists() {
        let counts = WindowInspector.classifyWindowCounts(
            appIsHidden: true,
            accessibilityWindows: [
                AccessibilityWindow(isMinimized: false),
                AccessibilityWindow(isMinimized: false),
            ],
            cgWindowCount: 0
        )

        XCTAssertEqual(counts, WindowCounts(open: 0, hidden: 2))
    }

    func testClassifyWindowCountsFallsBackToCgWindowCount() {
        let counts = WindowInspector.classifyWindowCounts(
            appIsHidden: false,
            accessibilityWindows: [],
            cgWindowCount: 4
        )

        XCTAssertEqual(counts, WindowCounts(open: 4, hidden: 0))
    }
}

