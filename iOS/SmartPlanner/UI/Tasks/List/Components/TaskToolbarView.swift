//
//  TaskToolbarView.swift
//  SmartPlanner
//
//  Subtitle counter shown under the large title.

import UIKit

final class TaskToolbarView: UIView {

    private let counterLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline)
        label.textColor = DesignTokens.Palette.secondaryText
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(counterLabel)
        NSLayoutConstraint.activate([
            counterLabel.topAnchor.constraint(equalTo: topAnchor),
            counterLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.Spacing.xs),
            counterLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.Spacing.l),
            counterLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -DesignTokens.Spacing.l)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setCount(_ count: Int) {
        counterLabel.text = TaskCountFormatter.localize(count: count)
    }
}

enum TaskCountFormatter {
    static func localize(count: Int) -> String {
        let mod10 = count % 10
        let mod100 = count % 100
        let word: String
        if mod10 == 1 && mod100 != 11 {
            word = "задача"
        } else if (2...4).contains(mod10) && !(12...14).contains(mod100) {
            word = "задачи"
        } else {
            word = "задач"
        }
        return "\(count) \(word)"
    }
}
