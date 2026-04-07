// SuperCloseRulesTests.swift
// Unit tests for `SuperCloseRules`: confirms the bundle-id → preferred-name
// overrides win over `localizedName`, that the skip lists filter system UI
// agents while still letting Finder through, and that the recommended-action
// heuristics return the expected Hide/Quit defaults for Finder, accessory
// apps, and regular windowed apps.

import AppKit
import XCTest
@testable import SuperClose

final class SuperCloseRulesTests: XCTestCase {
    private let rules = SuperCloseRules()

    func testPreferredDisplayNameUsesOverridesBeforeLocalizedName() {
        XCTAssertEqual(
            rules.preferredDisplayName(localizedName: "VS Code", bundleIdentifier: "com.microsoft.VSCode"),
            "Visual Studio Code"
        )
    }

    func testPreferredDisplayNameFallsBackToLocalizedName() {
        XCTAssertEqual(
            rules.preferredDisplayName(localizedName: "Safari", bundleIdentifier: "com.apple.Safari"),
            "Safari"
        )
    }

    func testShouldSkipFiltersSystemUiAgents() {
        XCTAssertTrue(
            rules.shouldSkip(
                displayName: "Control Center",
                bundleIdentifier: "com.apple.controlcenter",
                bundlePath: "/System/Library/CoreServices/ControlCenter.app"
            )
        )
    }

    func testShouldSkipAllowsFinder() {
        XCTAssertFalse(
            rules.shouldSkip(
                displayName: "Finder",
                bundleIdentifier: "com.apple.finder",
                bundlePath: "/System/Library/CoreServices/Finder.app"
            )
        )
    }

    func testFinderRecommendationIsHide() {
        let descriptor = AppDescriptor(
            displayName: "Finder",
            bundleIdentifier: "com.apple.finder",
            bundlePath: "/System/Library/CoreServices/Finder.app",
            activationPolicy: .regular,
            isFinder: true,
            isDockPinned: true,
            hasUIKitStyleBundleMetadata: false
        )

        XCTAssertEqual(rules.recommendedAction(for: descriptor), .hide)
    }

    func testAccessoryAppsDefaultToHide() {
        let descriptor = AppDescriptor(
            displayName: "Rectangle",
            bundleIdentifier: "com.knollsoft.Rectangle",
            bundlePath: "/Applications/Rectangle.app",
            activationPolicy: .accessory,
            isFinder: false,
            isDockPinned: false,
            hasUIKitStyleBundleMetadata: false
        )

        XCTAssertEqual(rules.recommendedAction(for: descriptor), .hide)
    }

    func testRegularWindowedAppsDefaultToQuit() {
        let descriptor = AppDescriptor(
            displayName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            bundlePath: "/Applications/Safari.app",
            activationPolicy: .regular,
            isFinder: false,
            isDockPinned: false,
            hasUIKitStyleBundleMetadata: false
        )

        XCTAssertEqual(rules.recommendedAction(for: descriptor), .quit)
    }
}

