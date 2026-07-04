//
//  UpcomingTaskCell.swift
//  SmartPlanner
//

import UIKit

final class UpcomingTaskCell: UIControl {

    var onToggleCompleted: (() -> Void)?

    private enum Constants {
        static let checkPointSize: CGFloat = 22
        static let flagPointSize: CGFloat = 13
        static let verticalPadding: CGFloat = 10
        static let horizontalSpacing: CGFloat = 12
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("ddMMM HHmm")
        return formatter
    }()

    private let priorityIndicator = TaskPriorityIndicator()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let flagImageView: UIImageView = {
        let view = UIImageView()
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: Constants.flagPointSize, weight: .semibold)
        view.image = UIImage(systemName: "flag.fill")
        view.tintColor = .systemOrange
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.isHidden = true
        return view
    }()

    private let checkButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        textStack.axis = .vertical
        textStack.spacing = DesignTokens.Spacing.xs
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [priorityIndicator, textStack, flagImageView, checkButton])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = Constants.horizontalSpacing
        row.isUserInteractionEnabled = true
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor, constant: Constants.verticalPadding),
            row.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.verticalPadding),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func configure(with task: Task) {
        titleLabel.text = task.title
        priorityIndicator.apply(priority: task.priority, dimmed: task.isCompleted)

        if let deadline = task.deadline {
            dateLabel.text = Self.dateFormatter.string(from: deadline)
            dateLabel.isHidden = false
        } else {
            dateLabel.isHidden = true
        }

        flagImageView.isHidden = !task.isFlagged

        let symbol = task.isCompleted ? "checkmark.circle.fill" : "circle"
        let config = UIImage.SymbolConfiguration(pointSize: Constants.checkPointSize, weight: .regular)
        checkButton.setImage(UIImage(systemName: symbol, withConfiguration: config), for: .normal)
        checkButton.tintColor = task.isCompleted ? .systemBlue : .tertiaryLabel

        accessibilityLabel = task.title
        accessibilityValue = task.isCompleted ? "выполнено" : "не выполнено"
    }

    @objc private func checkTapped() {
        onToggleCompleted?()
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
