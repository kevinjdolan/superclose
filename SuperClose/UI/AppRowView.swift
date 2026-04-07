// AppRowView.swift
// Custom NSView for a single row in the SuperClose review window: app icon,
// name, window-count detail line, and an `NSSegmentedControl` of action
// choices. Owns selection styling (`isRowSelected`), handles click-to-select,
// disables Quit/Kill for apps that can't be quit (e.g. Finder), and exposes
// `setAction(_:)` so the app delegate can drive it from keyboard shortcuts.

import AppKit
import Foundation

final class AppRowView: NSView {
    let candidate: AppCandidate
    let segmentedControl: NSSegmentedControl
    var onSelect: (() -> Void)?

    private let iconView: NSImageView
    private let nameLabel: NSTextField
    private let detailLabel: NSTextField
    private let backgroundView: NSView

    var selectedAction: SelectedAction {
        get { SelectedAction(rawValue: segmentedControl.selectedSegment) ?? .ignore }
        set { segmentedControl.selectedSegment = newValue.rawValue }
    }

    var enabledActions: [SelectedAction] {
        SelectedAction.allCases.filter { segmentedControl.isEnabled(forSegment: $0.rawValue) }
    }

    var isRowSelected = false {
        didSet {
            updateAppearance()
        }
    }

    init(candidate: AppCandidate) {
        self.candidate = candidate
        segmentedControl = NSSegmentedControl(
            labels: AppStrings.actionLabels,
            trackingMode: .selectOne,
            target: nil,
            action: nil
        )
        iconView = NSImageView(image: AppRowView.icon(for: candidate.app))
        nameLabel = NSTextField(labelWithString: candidate.displayName)
        detailLabel = NSTextField(labelWithString: AppStrings.detailText(for: candidate.windowCounts))
        backgroundView = NSView()

        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        wantsLayer = true

        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        backgroundView.wantsLayer = true
        backgroundView.layer?.cornerRadius = AppLayout.rowCornerRadius
        backgroundView.layer?.masksToBounds = true
        addSubview(backgroundView)

        let contentStack = NSStackView()
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.orientation = .horizontal
        contentStack.spacing = 8
        contentStack.alignment = .centerY
        backgroundView.addSubview(contentStack)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)

        let textStack = NSStackView()
        textStack.orientation = .vertical
        textStack.spacing = 1
        textStack.alignment = .leading

        let spacerView = NSView()
        spacerView.translatesAutoresizingMaskIntoConstraints = false

        nameLabel.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        detailLabel.font = NSFont.systemFont(ofSize: 11)
        detailLabel.textColor = .secondaryLabelColor
        detailLabel.lineBreakMode = .byTruncatingTail
        detailLabel.maximumNumberOfLines = 1

        contentStack.addArrangedSubview(iconView)
        textStack.addArrangedSubview(nameLabel)
        textStack.addArrangedSubview(detailLabel)

        segmentedControl.target = self
        segmentedControl.action = #selector(segmentedChanged)
        segmentedControl.selectedSegment = candidate.recommendedAction.rawValue
        segmentedControl.segmentStyle = .rounded
        segmentedControl.setWidth(64, forSegment: SelectedAction.ignore.rawValue)
        segmentedControl.setWidth(58, forSegment: SelectedAction.hide.rawValue)
        segmentedControl.setWidth(64, forSegment: SelectedAction.quit.rawValue)
        segmentedControl.setWidth(58, forSegment: SelectedAction.kill.rawValue)
        segmentedControl.toolTip = AppStrings.actionTooltip

        if !candidate.allowsQuit {
            segmentedControl.setEnabled(false, forSegment: SelectedAction.quit.rawValue)
            segmentedControl.setEnabled(false, forSegment: SelectedAction.kill.rawValue)
            if segmentedControl.selectedSegment == SelectedAction.quit.rawValue {
                segmentedControl.selectedSegment = SelectedAction.hide.rawValue
            }
        }

        contentStack.addArrangedSubview(textStack)
        contentStack.addArrangedSubview(spacerView)
        contentStack.addArrangedSubview(segmentedControl)

        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacerView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        segmentedControl.setContentHuggingPriority(.required, for: .horizontal)

        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick))
        addGestureRecognizer(clickGesture)

        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStack.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: AppLayout.rowInset),
            contentStack.trailingAnchor.constraint(equalTo: backgroundView.trailingAnchor, constant: -AppLayout.rowInset),
            contentStack.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: AppLayout.rowInset),
            contentStack.bottomAnchor.constraint(equalTo: backgroundView.bottomAnchor, constant: -AppLayout.rowInset),

            iconView.heightAnchor.constraint(equalToConstant: AppLayout.iconSize),
            iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor),
            heightAnchor.constraint(equalToConstant: AppLayout.rowHeight),
        ])

        updateAppearance()
    }

    @objc private func handleClick() {
        onSelect?()
    }

    @objc private func segmentedChanged() {
        onSelect?()
    }

    func setAction(_ action: SelectedAction) {
        guard segmentedControl.isEnabled(forSegment: action.rawValue) else {
            return
        }

        segmentedControl.selectedSegment = action.rawValue
    }

    private func updateAppearance() {
        if isRowSelected {
            backgroundView.layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.24).cgColor
            nameLabel.textColor = .white
            detailLabel.textColor = NSColor.white.withAlphaComponent(0.82)
        } else {
            backgroundView.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.04).cgColor
            nameLabel.textColor = .labelColor
            detailLabel.textColor = .secondaryLabelColor
        }
    }

    private static func icon(for app: NSRunningApplication) -> NSImage {
        let image = app.icon
            ?? app.bundleURL.map { NSWorkspace.shared.icon(forFile: $0.path) }
            ?? NSImage(named: NSImage.applicationIconName)
            ?? NSImage(size: NSSize(width: AppLayout.iconSize, height: AppLayout.iconSize))
        image.size = NSSize(width: AppLayout.iconSize, height: AppLayout.iconSize)
        return image
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

