//
//  PrioritySelectorView.swift
//  SmartPlanner
//

import UIKit

final class PrioritySelectorView: UIView {

    var onSelectionChanged: ((TaskPriority) -> Void)?

    private(set) var selectedPriority: TaskPriority = .medium {
        didSet { updateButtonsAppearance() }
    }

    private var buttons: [TaskPriority: UIButton] = [:]

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        let header = FormHeaderView(
            symbolName: "flag.checkered",
            title: "Приоритет",
            showsTrailingLabel: false
        )

        let buttonStack = UIStackView()
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = DesignTokens.Spacing.s
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        TaskPriority.allCases.forEach { priority in
            let button = makeButton(for: priority)
            buttons[priority] = button
            buttonStack.addArrangedSubview(button)
        }

        let stack = UIStackView(arrangedSubviews: [header, buttonStack])
        stack.axis = .vertical
        stack.spacing = DesignTokens.Spacing.m
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        updateButtonsAppearance()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setSelected(_ priority: TaskPriority) {
        selectedPriority = priority
    }

    private func makeButton(for priority: TaskPriority) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(priority.title, for: .normal)
        button.titleLabel?.font = DesignTokens.Typography.cardTitle()
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = DesignTokens.Radius.capsule
        button.layer.cornerCurve = .continuous
        button.layer.borderWidth = 1
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: DesignTokens.Sizing.priorityButtonHeight).isActive = true
        button.accessibilityLabel = "Приоритет \(priority.title)"
        button.accessibilityIdentifier = "createTask.priority.\(priority.identifierSuffix)"
        button.addAction(UIAction { [weak self] _ in
            self?.selectedPriority = priority
            self?.onSelectionChanged?(priority)
        }, for: .touchUpInside)
        return button
    }

    private func updateButtonsAppearance() {
        buttons.forEach { priority, button in
            let isSelected = priority == selectedPriority
            let color = priority.tintColor
            button.tintColor = color
            button.setTitleColor(isSelected ? color : DesignTokens.Palette.secondaryText, for: .normal)
            button.backgroundColor = isSelected
                ? color.withAlphaComponent(0.12)
                : DesignTokens.Palette.cardBackground
            button.layer.borderColor = isSelected
                ? color.cgColor
                : UIColor.separator.cgColor
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }
}

extension TaskPriority {
    var tintColor: UIColor {
        switch self {
        case .low: return .systemGreen
        case .medium: return .systemOrange
        case .high: return .systemRed
        }
    }

    var identifierSuffix: String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        }
    }
}
