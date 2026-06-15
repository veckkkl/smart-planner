//
//  CardView.swift
//  SmartPlanner
//

import UIKit

final class CardView: UIView {

    private enum Constants {
        static let contentInsets = UIEdgeInsets(
            top: DesignTokens.Spacing.l,
            left: DesignTokens.Spacing.l,
            bottom: DesignTokens.Spacing.l,
            right: DesignTokens.Spacing.l
        )
    }

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = DesignTokens.Spacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init(contentInsets: UIEdgeInsets = Constants.contentInsets, spacing: CGFloat = DesignTokens.Spacing.m) {
        super.init(frame: .zero)
        contentStack.spacing = spacing
        setup(insets: contentInsets)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func setup(insets: UIEdgeInsets) {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DesignTokens.Palette.cardBackground
        layer.cornerRadius = DesignTokens.Radius.card
        layer.cornerCurve = .continuous

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = DesignTokens.Shadow.opacity
        layer.shadowRadius = DesignTokens.Shadow.radius
        layer.shadowOffset = DesignTokens.Shadow.offset

        addSubview(contentStack)
        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            contentStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            contentStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            contentStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom)
        ])
    }

    func addArrangedSubview(_ view: UIView) {
        contentStack.addArrangedSubview(view)
    }

    func setCustomSpacing(_ spacing: CGFloat, after view: UIView) {
        contentStack.setCustomSpacing(spacing, after: view)
    }
}
