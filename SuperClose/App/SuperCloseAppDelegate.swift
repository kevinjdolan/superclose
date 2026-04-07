// SuperCloseAppDelegate.swift
// The NSApplicationDelegate that owns the review window. Builds the row list
// from the candidates handed in by `main.swift`, wires up the keyboard monitor
// (arrows to navigate, A/S/D/F to set Ignore/Hide/Quit/Kill, Enter to run, Esc
// to cancel), keeps the Run button title in sync with the current selections,
// and on Run hands the selections to `ActionRunner` and surfaces any failures
// in a final alert before terminating.

import AppKit
import Foundation

final class SuperCloseAppDelegate: NSObject, NSApplicationDelegate {
    private let candidates: [AppCandidate]
    private let actionRunner = ActionRunner()
    private var window: NSWindow?
    private var rowViews: [AppRowView] = []
    private weak var runButton: NSButton?
    private var selectedRowIndex = 0
    private var keyMonitor: Any?

    init(candidates: [AppCandidate]) {
        self.candidates = candidates
    }

    deinit {
        if let keyMonitor {
            NSEvent.removeMonitor(keyMonitor)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if candidates.isEmpty {
            showAlert(title: AppStrings.emptyStateTitle, message: AppStrings.emptyStateMessage)
            NSApp.terminate(nil)
            return
        }

        buildWindow()
    }

    @objc private func performSelections() {
        let selections = rowViews.map { rowView in
            let selectedAction = SelectedAction(rawValue: rowView.segmentedControl.selectedSegment) ?? .ignore
            return (rowView.candidate, selectedAction)
        }

        window?.orderOut(nil)
        let summary = actionRunner.run(selections)

        if !summary.failures.isEmpty {
            showAlert(
                title: AppStrings.finishedWithNotesTitle,
                message: summary.failures.joined(separator: "\n")
            )
        }

        NSApp.terminate(nil)
    }

    @objc private func cancel() {
        NSApp.terminate(nil)
    }

    private func buildWindow() {
        let rowCount = CGFloat(candidates.count)
        let rowsHeight = rowCount * AppLayout.rowHeight + max(0, rowCount - 1) * AppLayout.rowSpacing
        let maxListHeight = AppLayout.maxVisibleItems * AppLayout.rowHeight
            + max(0, AppLayout.maxVisibleItems - 1) * AppLayout.rowSpacing
            + (AppLayout.verticalListPadding * 2)
        let listHeight = min(maxListHeight, rowsHeight + (AppLayout.verticalListPadding * 2))
        let contentHeight = listHeight + AppLayout.footerHeight

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: AppLayout.contentFrameWidth, height: contentHeight),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = AppStrings.windowTitle
        window.center()
        window.isReleasedWhenClosed = false
        window.level = .floating
        window.setFrameAutosaveName("SuperCloseWindow")
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.delegate = self

        let root = NSStackView()
        root.translatesAutoresizingMaskIntoConstraints = false
        root.orientation = .vertical
        root.alignment = .leading
        root.spacing = 6
        root.edgeInsets = NSEdgeInsets(top: 20, left: 15, bottom: 20, right: 15)

        let titleLabel = NSTextField(labelWithString: AppStrings.windowHeader)
        titleLabel.font = NSFont.systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = .labelColor

        let rowsStack = NSStackView()
        rowsStack.orientation = .vertical
        rowsStack.spacing = AppLayout.rowSpacing
        rowsStack.alignment = .leading
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        for (index, candidate) in candidates.enumerated() {
            let rowView = AppRowView(candidate: candidate)
            rowView.onSelect = { [weak self] in
                self?.selectRow(at: index, scrollIntoView: false)
                self?.updateRunButtonTitle()
            }
            rowViews.append(rowView)
            rowsStack.addArrangedSubview(rowView)
        }

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = false
        scrollView.scrollerStyle = .legacy
        scrollView.drawsBackground = true
        scrollView.backgroundColor = NSColor(calibratedWhite: 0.16, alpha: 1.0)
        scrollView.wantsLayer = true
        scrollView.layer?.borderWidth = 1
        scrollView.layer?.borderColor = NSColor.white.withAlphaComponent(0.08).cgColor

        let rowsContainer = FlippedView()
        rowsContainer.translatesAutoresizingMaskIntoConstraints = false
        rowsContainer.wantsLayer = true
        rowsContainer.layer?.backgroundColor = NSColor(calibratedWhite: 0.16, alpha: 1.0).cgColor
        rowsContainer.addSubview(rowsStack)
        scrollView.documentView = rowsContainer

        NSLayoutConstraint.activate([
            rowsStack.leadingAnchor.constraint(equalTo: rowsContainer.leadingAnchor, constant: AppLayout.listLeftPadding),
            rowsStack.trailingAnchor.constraint(equalTo: rowsContainer.trailingAnchor, constant: -AppLayout.listRightPadding),
            rowsStack.topAnchor.constraint(equalTo: rowsContainer.topAnchor, constant: AppLayout.verticalListPadding),
            rowsStack.bottomAnchor.constraint(equalTo: rowsContainer.bottomAnchor, constant: -AppLayout.verticalListPadding),
            rowsStack.widthAnchor.constraint(
                equalTo: rowsContainer.widthAnchor,
                constant: -(AppLayout.listLeftPadding + AppLayout.listRightPadding)
            ),
        ])

        let legendLabel = NSTextField(labelWithString: "")
        legendLabel.translatesAutoresizingMaskIntoConstraints = false
        legendLabel.attributedStringValue = attributedLegend()
        legendLabel.font = NSFont.systemFont(ofSize: 11)
        legendLabel.textColor = .secondaryLabelColor
        legendLabel.alignment = .right
        legendLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        legendLabel.setContentHuggingPriority(.required, for: .horizontal)

        let legendWrap = NSView()
        legendWrap.translatesAutoresizingMaskIntoConstraints = false
        legendWrap.addSubview(legendLabel)

        let buttonRow = NSStackView()
        buttonRow.translatesAutoresizingMaskIntoConstraints = false
        buttonRow.orientation = .horizontal
        buttonRow.alignment = .centerY
        buttonRow.spacing = AppLayout.buttonGap
        buttonRow.distribution = .fill

        let cancelButton = NSButton(title: AppStrings.cancelButtonTitle, target: self, action: #selector(cancel))
        cancelButton.keyEquivalent = "\u{1b}"

        let runButton = NSButton(title: "", target: self, action: #selector(performSelections))
        runButton.keyEquivalent = "\r"
        runButton.bezelStyle = .rounded
        self.runButton = runButton
        updateRunButtonTitle()

        let footerWrap = NSView()
        footerWrap.translatesAutoresizingMaskIntoConstraints = false
        footerWrap.addSubview(buttonRow)

        buttonRow.addArrangedSubview(cancelButton)
        buttonRow.addArrangedSubview(runButton)

        root.addArrangedSubview(titleLabel)
        root.addArrangedSubview(scrollView)
        root.addArrangedSubview(legendWrap)
        root.addArrangedSubview(footerWrap)

        window.contentView = root

        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: window.contentView!.leadingAnchor),
            root.trailingAnchor.constraint(equalTo: window.contentView!.trailingAnchor),
            root.topAnchor.constraint(equalTo: window.contentView!.topAnchor),
            root.bottomAnchor.constraint(equalTo: window.contentView!.bottomAnchor),

            titleLabel.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            scrollView.widthAnchor.constraint(equalToConstant: AppLayout.contentWidth),
            scrollView.heightAnchor.constraint(equalToConstant: listHeight),
            rowsContainer.widthAnchor.constraint(equalTo: scrollView.contentView.widthAnchor),

            legendWrap.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            legendLabel.leadingAnchor.constraint(greaterThanOrEqualTo: legendWrap.leadingAnchor, constant: 5),
            legendLabel.trailingAnchor.constraint(equalTo: legendWrap.trailingAnchor),
            legendLabel.topAnchor.constraint(equalTo: legendWrap.topAnchor),
            legendLabel.bottomAnchor.constraint(equalTo: legendWrap.bottomAnchor),

            footerWrap.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            footerWrap.topAnchor.constraint(equalTo: legendWrap.bottomAnchor, constant: 10),
            buttonRow.leadingAnchor.constraint(equalTo: footerWrap.leadingAnchor),
            buttonRow.trailingAnchor.constraint(equalTo: footerWrap.trailingAnchor),
            buttonRow.topAnchor.constraint(equalTo: footerWrap.topAnchor),
            buttonRow.bottomAnchor.constraint(equalTo: footerWrap.bottomAnchor),
            cancelButton.widthAnchor.constraint(equalToConstant: AppLayout.cancelButtonWidth),
            runButton.widthAnchor.constraint(equalTo: footerWrap.widthAnchor, constant: -AppLayout.footerRunButtonOffset),
        ])

        self.window = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        installKeyboardMonitor()
        selectRow(at: 0, scrollIntoView: true)
    }

    private func installKeyboardMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self else {
                return event
            }

            return handleKeyDown(event) ? nil : event
        }
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option) {
            return false
        }

        switch event.keyCode {
        case 36, 76:
            performSelections()
            return true
        case 53:
            cancel()
            return true
        case 125:
            moveSelection(delta: 1)
            return true
        case 126:
            moveSelection(delta: -1)
            return true
        case 123:
            cycleSelectedRowAction(direction: -1)
            return true
        case 124:
            cycleSelectedRowAction(direction: 1)
            return true
        default:
            break
        }

        switch event.charactersIgnoringModifiers?.lowercased() {
        case "a":
            setSelectedRowAction(.ignore)
            return true
        case "s":
            setSelectedRowAction(.hide)
            return true
        case "d":
            setSelectedRowAction(.quit)
            return true
        case "f":
            setSelectedRowAction(.kill)
            return true
        default:
            return false
        }
    }

    private func moveSelection(delta: Int) {
        guard !rowViews.isEmpty else {
            return
        }

        let nextIndex = max(0, min(rowViews.count - 1, selectedRowIndex + delta))
        selectRow(at: nextIndex, scrollIntoView: true)
    }

    private func selectRow(at index: Int, scrollIntoView: Bool) {
        guard rowViews.indices.contains(index) else {
            return
        }

        selectedRowIndex = index

        for (rowIndex, rowView) in rowViews.enumerated() {
            rowView.isRowSelected = rowIndex == index
        }

        if scrollIntoView {
            rowViews[index].scrollToVisible(rowViews[index].bounds.insetBy(dx: 0, dy: -10))
        }
    }

    private func cycleSelectedRowAction(direction: Int) {
        guard rowViews.indices.contains(selectedRowIndex) else {
            return
        }

        let rowView = rowViews[selectedRowIndex]
        let enabledActions = rowView.enabledActions

        guard !enabledActions.isEmpty,
              let currentIndex = enabledActions.firstIndex(of: rowView.selectedAction) else {
            return
        }

        let nextIndex = (currentIndex + direction + enabledActions.count) % enabledActions.count
        rowView.setAction(enabledActions[nextIndex])
        updateRunButtonTitle()
    }

    private func setSelectedRowAction(_ action: SelectedAction) {
        guard rowViews.indices.contains(selectedRowIndex) else {
            return
        }

        rowViews[selectedRowIndex].setAction(action)
        updateRunButtonTitle()
    }

    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = title
        alert.informativeText = message
        alert.addButton(withTitle: AppStrings.okayButtonTitle)
        alert.runModal()
    }

    private func attributedLegend() -> NSAttributedString {
        let normalFont = NSFont.systemFont(ofSize: 11, weight: .regular)
        let boldFont = NSFont.systemFont(ofSize: 11, weight: .semibold)
        let defaultColor = NSColor.secondaryLabelColor
        let keyColor = NSColor.white

        let result = NSMutableAttributedString()
        for (index, entry) in AppStrings.legendEntries.enumerated() {
            if index > 0 {
                result.append(
                    NSAttributedString(
                        string: " • ",
                        attributes: [.font: normalFont, .foregroundColor: defaultColor]
                    )
                )
            }

            result.append(
                NSAttributedString(
                    string: entry.key,
                    attributes: [.font: boldFont, .foregroundColor: keyColor]
                )
            )
            result.append(
                NSAttributedString(
                    string: " \(entry.description)",
                    attributes: [.font: normalFont, .foregroundColor: defaultColor]
                )
            )
        }

        return result
    }

    private func updateRunButtonTitle() {
        var quitCount = 0
        var hideCount = 0
        var killCount = 0

        for rowView in rowViews {
            switch rowView.selectedAction {
            case .ignore:
                break
            case .hide:
                hideCount += 1
            case .quit:
                quitCount += 1
            case .kill:
                killCount += 1
            }
        }

        runButton?.title = AppStrings.runButtonTitle(
            quitCount: quitCount,
            hideCount: hideCount,
            killCount: killCount
        )
    }
}

extension SuperCloseAppDelegate: NSWindowDelegate {
    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil)
    }
}

