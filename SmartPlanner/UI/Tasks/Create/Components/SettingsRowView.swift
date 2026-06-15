//
//  SettingsRowView.swift
//  SmartPlanner
//

import UIKit

final class SettingsRowView: UIView {

    var onValueChanged: ((Bool) -> Void)?

    var isOn: Bool {
        get { toggle.isOn }
        set { toggle.setOn(newValue, animated: false) }
    }

    private let iconView: UIImageView = {
        let view = UIImageView()
        view.tintColor = DesignTokens.Palette.accent
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.value()
        label.textColor = DesignTokens.Palette.primaryText
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.caption()
        label.textColor = DesignTokens.Palette.secondaryText
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }()

    private let toggle: UISwitch = {
        let toggle = UISwitch()
        toggle.onTintColor = DesignTokens.Palette.accent
        toggle.translatesAutoresizingMaskIntoConstraints = false
        return toggle
    }()

    init(symbolName: String, title: String, subtitle: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        iconView.image = UIImage(systemName: symbolName)
        titleLabel.text = title
        subtitleLabel.text = subtitle

        let textStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        textStack.axis = .vertical
        textStack.spacing = DesignTokens.Spacing.xs

        let stack = UIStackView(arrangedSubviews: [iconView, textStack, toggle])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = DesignTokens.Spacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            iconView.widthAnchor.constraint(equalToConstant: DesignTokens.Sizing.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: DesignTokens.Sizing.iconSize)
        ])

        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)
        accessibilityElements = [titleLabel, subtitleLabel, toggle]
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    @objc private func toggleChanged() {
        onValueChanged?(toggle.isOn)
    }
}

final class SeparatorView: UIView {
    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DesignTokens.Palette.separator
        heightAnchor.constraint(equalToConstant: DesignTokens.Sizing.separatorHeight).isActive = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}
