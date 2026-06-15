//
//  TaskPriorityIndicator.swift
//  SmartPlanner
//

import UIKit

final class TaskPriorityIndicator: UIView {

    private enum Constants {
        static let width: CGFloat = 4
        static let height: CGFloat = 32
        static let cornerRadius: CGFloat = 2
    }

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = Constants.cornerRadius
        layer.cornerCurve = .continuous
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: Constants.width),
            heightAnchor.constraint(equalToConstant: Constants.height)
        ])
        isAccessibilityElement = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func apply(priority: TaskPriority, dimmed: Bool) {
        backgroundColor = priority.tintColor.withAlphaComponent(dimmed ? 0.35 : 1.0)
    }
}
