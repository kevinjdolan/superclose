// CommandLineReporterTests.swift
// Tests for the CLI formatting helpers in `CommandLineReporter`: that
// `usageText` advertises the supported flags and executable name, and that
// `dumpText(for:)` renders an `AppCandidate` as the documented tab-separated
// `name<TAB>open=N<TAB>hidden=N<TAB>action` line.

import AppKit
import XCTest
@testable import SuperClose

final class CommandLineReporterTests: XCTestCase {
    func testUsageTextIncludesSupportedFlags() {
        let usageText = CommandLineReporter.usageText

        XCTAssertTrue(usageText.contains("--help"))
        XCTAssertTrue(usageText.contains("--dump"))
        XCTAssertTrue(usageText.contains(AppStrings.executableName))
    }

    func testDumpTextPrintsTabSeparatedSummary() {
        let candidate = AppCandidate(
            app: NSRunningApplication.current,
            descriptor: AppDescriptor(
                displayName: "Safari",
                bundleIdentifier: "com.apple.Safari",
                bundlePath: "/Applications/Safari.app",
                activationPolicy: .regular,
                isFinder: false,
                isDockPinned: true,
                hasUIKitStyleBundleMetadata: false
            ),
            windowCounts: WindowCounts(open: 3, hidden: 1),
            recommendedAction: .quit
        )

        XCTAssertEqual(
            CommandLineReporter.dumpText(for: [candidate]),
            "Safari\topen=3\thidden=1\tquit"
        )
    }
}
