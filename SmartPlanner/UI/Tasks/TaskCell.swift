//
//  TaskCell.swift
//  SmartPlanner
//

import UIKit

final class TaskCell: UITableViewCell {

    static let reuseIdentifier = "TaskCell"

    var onToggleCompleted: (() -> Void)?

    private enum Constants {
        static let checkPointSize: CGFloat = 22
        static let metaIconPointSize: CGFloat = 11
        static let flagPointSize: CGFloat = 14
        static let verticalPadding: CGFloat = 10
        static let horizontalSpacing: CGFloat = 12
        static let metaSpacing: CGFloat = 4
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("ddMMM")
        return formatter
    }()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.timeStyle = .short
        return formatter
    }()

    private let priorityIndicator = TaskPriorityIndicator()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let detailsLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 2
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 1
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
        button.tintColor = .systemBlue
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.accessibilityLabel = "Отметить выполненной"
        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func setupViews() {
        backgroundColor = .systemBackground
        accessoryType = .none

        let metaStack = UIStackView(arrangedSubviews: [dateLabel])
        metaStack.axis = .horizontal
        metaStack.spacing = Constants.metaSpacing
        metaStack.alignment = .center

        let textStack = UIStackView(arrangedSubviews: [titleLabel, detailsLabel, metaStack])
        textStack.axis = .vertical
        textStack.spacing = DesignTokens.Spacing.xs
        textStack.translatesAutoresizingMaskIntoConstraints = false
        textStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let rowStack = UIStackView(arrangedSubviews: [priorityIndicator, textStack, flagImageView, checkButton])
        rowStack.axis = .horizontal
        rowStack.alignment = .center
        rowStack.spacing = Constants.horizontalSpacing
        rowStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(rowStack)
        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Constants.verticalPadding),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Constants.verticalPadding),
            rowStack.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)
        ])

        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)
    }

    func configure(with task: Task) {
        titleLabel.text = task.title
        titleLabel.accessibilityIdentifier = "taskCell.title.\(task.title)"
        checkButton.accessibilityIdentifier = "taskCell.completeButton.\(task.title)"
        priorityIndicator.apply(priority: task.priority, dimmed: task.isCompleted)

        if let details = task.details, !details.isEmpty {
            detailsLabel.text = details
            detailsLabel.isHidden = false
        } else {
            detailsLabel.isHidden = true
        }

        configureDate(for: task)
        configureCheck(for: task)
        configureCompletion(for: task)

        flagImageView.isHidden = !task.isFlagged
        accessibilityLabel = accessibilityDescription(for: task)
    }

    private func configureDate(for task: Task) {
        guard let deadline = task.deadline else {
            dateLabel.isHidden = true
            return
        }
        dateLabel.isHidden = false
        let dateString = Self.dateFormatter.string(from: deadline)
        let timeString = Self.timeFormatter.string(from: deadline)
        let attributed = NSMutableAttributedString()
        attributed.append(symbolAttachment("calendar"))
        attributed.append(NSAttributedString(string: " \(dateString)  "))
        attributed.append(symbolAttachment("clock"))
        attributed.append(NSAttributedString(string: " \(timeString)"))
        dateLabel.attributedText = attributed
    }

    private func symbolAttachment(_ name: String) -> NSAttributedString {
        let config = UIImage.SymbolConfiguration(pointSize: Constants.metaIconPointSize, weight: .semibold)
        guard let image = UIImage(systemName: name, withConfiguration: config) else {
            return NSAttributedString()
        }
        let attachment = NSTextAttachment(image: image.withTintColor(.secondaryLabel, renderingMode: .alwaysTemplate))
        return NSAttributedString(attachment: attachment)
    }

    private func configureCheck(for task: Task) {
        let symbolName = task.isCompleted ? "checkmark.circle.fill" : "circle"
        let config = UIImage.SymbolConfiguration(pointSize: Constants.checkPointSize, weight: .regular)
        let image = UIImage(systemName: symbolName, withConfiguration: config)
        checkButton.setImage(image, for: .normal)
        checkButton.tintColor = task.isCompleted ? .systemBlue : .tertiaryLabel
        checkButton.accessibilityValue = task.isCompleted ? "выполнено" : "не выполнено"
    }

    private func configureCompletion(for task: Task) {
        let dim: CGFloat = task.isCompleted ? 0.4 : 1
        titleLabel.alpha = dim
        detailsLabel.alpha = dim
        dateLabel.alpha = dim
        let style = task.isCompleted ? NSUnderlineStyle.single.rawValue : 0
        titleLabel.attributedText = NSAttributedString(
            string: task.title,
            attributes: [.strikethroughStyle: style]
        )
    }

    private func accessibilityDescription(for task: Task) -> String {
        var parts: [String] = [task.title, "приоритет \(task.priority.title)"]
        if task.isCompleted { parts.append("выполнено") }
        if task.isFlagged { parts.append("с флагом") }
        return parts.joined(separator: ", ")
    }

    @objc private func checkTapped() {
        onToggleCompleted?()
    }
}
