//
//  TaskCell.swift
//  SmartPlanner
//
//  Created by valentina balde on 12/7/25.
//

import UIKit

final class TaskCell: UITableViewCell {

    static let reuseIdentifier = "TaskCell"

    var onToggleCompleted: (() -> Void)?

    private let priorityView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let flagImageView = UIImageView()
    private let checkButton = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func setupViews() {
        selectionStyle = .none

        priorityView.translatesAutoresizingMaskIntoConstraints = false
        priorityView.layer.cornerRadius = 4

        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 2
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        flagImageView.image = UIImage(systemName: "flag.fill")
        flagImageView.tintColor = .systemRed
        flagImageView.translatesAutoresizingMaskIntoConstraints = false
        flagImageView.isHidden = true

        checkButton.setTitle("○", for: .normal)
        checkButton.translatesAutoresizingMaskIntoConstraints = false
        checkButton.addTarget(self, action: #selector(checkTapped), for: .touchUpInside)

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(priorityView)
        contentView.addSubview(checkButton)
        contentView.addSubview(flagImageView)
        contentView.addSubview(labelsStack)

        NSLayoutConstraint.activate([
            priorityView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            priorityView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            priorityView.widthAnchor.constraint(equalToConstant: 8),
            priorityView.heightAnchor.constraint(equalToConstant: 32),

            checkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            flagImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagImageView.trailingAnchor.constraint(equalTo: checkButton.leadingAnchor, constant: -8),
            flagImageView.widthAnchor.constraint(equalToConstant: 16),
            flagImageView.heightAnchor.constraint(equalToConstant: 16),

            labelsStack.leadingAnchor.constraint(equalTo: priorityView.trailingAnchor, constant: 12),
            labelsStack.trailingAnchor.constraint(lessThanOrEqualTo: flagImageView.leadingAnchor, constant: -8),
            labelsStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            labelsStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])

        checkButton.setContentHuggingPriority(.required, for: .horizontal)
        flagImageView.setContentHuggingPriority(.required, for: .horizontal)
        labelsStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    func configure(with task: Task) {
        titleLabel.text = task.title

        var parts: [String] = []
        if let details = task.details, details.isEmpty == false {
            parts.append(details)
        }
        if let deadline = task.deadline {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM HH:mm"
            parts.append(formatter.string(from: deadline))
        }
        subtitleLabel.text = parts.joined(separator: " • ")

        let alpha: CGFloat = task.isCompleted ? 0.4 : 1
        titleLabel.alpha = alpha
        subtitleLabel.alpha = alpha

        let color: UIColor
        switch task.priority {
        case .low: color = .systemGreen
        case .medium: color = .systemOrange
        case .high: color = .systemRed
        }
        priorityView.backgroundColor = color

        let checkTitle = task.isCompleted ? "✓" : "○"
        checkButton.setTitle(checkTitle, for: .normal)
        flagImageView.isHidden = task.isFlagged == false
    }

    @objc
    private func checkTapped() {
        onToggleCompleted?()
    }
}
