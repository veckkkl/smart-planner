//
//  TaskSectionHeaderView.swift
//  SmartPlanner
//

import UIKit

final class TaskSectionHeaderView: UITableViewHeaderFooterView {

    static let reuseIdentifier = "TaskSectionHeaderView"

    var onToggle: (() -> Void)?

    private enum Constants {
        static let chevronPointSize: CGFloat = 13
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .secondaryLabel
        return label
    }()

    private let chevron: UIImageView = {
        let view = UIImageView()
        view.tintColor = .tertiaryLabel
        view.contentMode = .scaleAspectFit
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: Constants.chevronPointSize, weight: .semibold
        )
        view.image = UIImage(systemName: "chevron.down")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        let stack = UIStackView(arrangedSubviews: [titleLabel, countLabel, UIView(), chevron])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = DesignTokens.Spacing.s
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: DesignTokens.Spacing.s),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -DesignTokens.Spacing.s),
            stack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        contentView.addGestureRecognizer(recognizer)
        contentView.isUserInteractionEnabled = true
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(title: String, count: Int, isCollapsed: Bool) {
        titleLabel.text = title
        countLabel.text = "\(count)"
        let target: CGAffineTransform = isCollapsed
            ? CGAffineTransform(rotationAngle: .pi / 2)
            : .identity
        if chevron.transform != target {
            UIView.animate(withDuration: 0.25) { self.chevron.transform = target }
        }
        accessibilityLabel = "\(title), \(count)"
        accessibilityValue = isCollapsed ? "свернуто" : "развернуто"
    }

    @objc private func tapped() {
        onToggle?()
    }
}
