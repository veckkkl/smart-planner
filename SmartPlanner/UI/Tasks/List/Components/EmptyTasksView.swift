//
//  EmptyTasksView.swift
//  SmartPlanner
//

import UIKit

final class EmptyTasksView: UIView {

    var onCreateTapped: (() -> Void)?

    private enum Strings {
        static let title = "Нет задач"
        static let subtitle = "Создайте первую задачу"
        static let button = "Новая задача"
    }

    private enum Constants {
        static let iconPointSize: CGFloat = 56
    }

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        let iconView = UIImageView(image: UIImage(
            systemName: "checklist",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconPointSize, weight: .regular)
        ))
        iconView.tintColor = DesignTokens.Palette.secondaryText
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = Strings.title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2).withSemibold()
        titleLabel.textColor = DesignTokens.Palette.primaryText
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center

        let subtitleLabel = UILabel()
        subtitleLabel.text = Strings.subtitle
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.textColor = DesignTokens.Palette.secondaryText
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0

        var config = UIButton.Configuration.borderedTinted()
        config.title = Strings.button
        config.image = UIImage(systemName: "plus")
        config.imagePadding = DesignTokens.Spacing.s
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.onCreateTapped?()
        })
        button.tintColor = DesignTokens.Palette.accent

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, subtitleLabel, button])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = DesignTokens.Spacing.m
        stack.setCustomSpacing(DesignTokens.Spacing.l, after: subtitleLabel)
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: DesignTokens.Spacing.xxl),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -DesignTokens.Spacing.xxl)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }
}

private extension UIFont {
    func withSemibold() -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
