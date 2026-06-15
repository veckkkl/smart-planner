//
//  TipCardView.swift
//  SmartPlanner
//

import UIKit

final class TipCardView: UIView {

    init(title: String, message: String) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        backgroundColor = DesignTokens.Palette.tipBackground
        layer.cornerRadius = DesignTokens.Radius.card
        layer.cornerCurve = .continuous

        let iconView = UIImageView(image: UIImage(systemName: "sparkles"))
        iconView.tintColor = DesignTokens.Palette.accent
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.setContentHuggingPriority(.required, for: .horizontal)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = DesignTokens.Typography.cardTitle()
        titleLabel.textColor = DesignTokens.Palette.primaryText
        titleLabel.adjustsFontForContentSizeCategory = true

        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.font = DesignTokens.Typography.caption()
        messageLabel.textColor = DesignTokens.Palette.secondaryText
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.numberOfLines = 0

        let textStack = UIStackView(arrangedSubviews: [titleLabel, messageLabel])
        textStack.axis = .vertical
        textStack.spacing = DesignTokens.Spacing.xs

        let stack = UIStackView(arrangedSubviews: [iconView, textStack])
        stack.axis = .horizontal
        stack.alignment = .top
        stack.spacing = DesignTokens.Spacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.Spacing.l),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.Spacing.l),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.Spacing.l),

            iconView.widthAnchor.constraint(equalToConstant: DesignTokens.Sizing.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: DesignTokens.Sizing.iconSize)
        ])

        isAccessibilityElement = true
        accessibilityLabel = "\(title). \(message)"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}
