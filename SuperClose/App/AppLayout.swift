// AppLayout.swift
// Central bag of layout constants (row heights, paddings, button widths, etc.)
// shared by `SuperCloseAppDelegate` and `AppRowView`. Keeping them in one place
// makes it easy to tweak the review window's spacing without hunting through
// view code.

import AppKit

enum AppLayout {
    static let rowHeight: CGFloat = 48
    static let rowSpacing: CGFloat = 6
    static let listLeftPadding: CGFloat = 10
    static let listRightPadding: CGFloat = 15
    static let verticalListPadding: CGFloat = 10
    static let maxVisibleItems: CGFloat = 8
    static let contentWidth: CGFloat = 620
    static let contentFrameWidth: CGFloat = 650
    static let footerHeight: CGFloat = 76
    static let rowCornerRadius: CGFloat = 10
    static let rowInset: CGFloat = 5
    static let iconSize: CGFloat = 28
    static let cancelButtonWidth: CGFloat = 130
    static let buttonGap: CGFloat = 10
    static let footerRunButtonOffset: CGFloat = 140
}

