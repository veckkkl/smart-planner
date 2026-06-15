//
//  EmptyDashboardView.swift
//  SmartPlanner
//

import UIKit

final class EmptyDashboardView: UIView {

    var onCreateTapped: (() -> Void)?

    private enum Strings {
        static let title = "Пока нет задач"
        static let subtitle = "Создайте первую задачу и начните планирование"
        static let button = "Создать задачу"
    }

    private enum Constants {
        static let iconPointSize: CGFloat = 64
    }

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear

        let icon = UIImageView(image: UIImage(
            systemName: "checklist",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: Constants.iconPointSize, weight: .regular)
        ))
        icon.tintColor = .secondaryLabel
        icon.contentMode = .scaleAspectFit

        let title = UILabel()
        title.text = Strings.title
        title.font = UIFont.preferredFont(forTextStyle: .title2).withSemibold()
        title.adjustsFontForContentSizeCategory = true
        title.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = Strings.subtitle
        subtitle.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitle.textColor = .secondaryLabel
        subtitle.adjustsFontForContentSizeCategory = true
        subtitle.textAlignment = .center
        subtitle.numberOfLines = 0

        var config = UIButton.Configuration.borderedProminent()
        config.title = Strings.button
        config.image = UIImage(systemName: "plus")
        config.imagePadding = DesignTokens.Spacing.s
        config.cornerStyle = .capsule
        let button = UIButton(configuration: config, primaryAction: UIAction { [weak self] _ in
            self?.onCreateTapped?()
        })

        let stack = UIStackView(arrangedSubviews: [icon, title, subtitle, button])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = DesignTokens.Spacing.m
        stack.setCustomSpacing(DesignTokens.Spacing.l, after: subtitle)
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
