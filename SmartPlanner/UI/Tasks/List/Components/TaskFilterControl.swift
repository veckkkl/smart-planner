//
//  TaskFilterControl.swift
//  SmartPlanner
//

import UIKit

final class TaskFilterControl: UIView {

    var onSelectionChange: ((TaskFilter) -> Void)?

    var selected: TaskFilter {
        get { TaskFilter(rawValue: segmented.selectedSegmentIndex) ?? .all }
        set { segmented.selectedSegmentIndex = newValue.rawValue }
    }

    private let segmented: UISegmentedControl = {
        let control = UISegmentedControl(items: TaskFilter.allCases.map(\.title))
        control.selectedSegmentIndex = TaskFilter.all.rawValue
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(segmented)
        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.Spacing.s),
            segmented.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.Spacing.s),
            segmented.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.Spacing.l),
            segmented.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.Spacing.l)
        ])
        segmented.addTarget(self, action: #selector(changed), for: .valueChanged)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    @objc private func changed() {
        onSelectionChange?(selected)
    }
}
