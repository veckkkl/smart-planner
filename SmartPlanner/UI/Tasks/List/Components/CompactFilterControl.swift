//
//  CompactFilterControl.swift
//  SmartPlanner
//

import UIKit

final class CompactFilterControl: UIView {

    var onSelectionChange: ((TaskFilter) -> Void)?

    private enum Constants {
        static let animationDuration: TimeInterval = 0.25
    }

    private(set) var selected: TaskFilter = .all

    private var buttons: [TaskFilter: CompactFilterButton] = [:]
    private let stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = DesignTokens.Spacing.s
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        for filter in TaskFilter.allCases {
            let button = CompactFilterButton(filter: filter)
            button.addAction(UIAction { [weak self] _ in
                self?.handleTap(filter)
            }, for: .touchUpInside)
            buttons[filter] = button
            stack.addArrangedSubview(button)
        }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.Spacing.s),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.Spacing.s),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor)
        ])

        applySelection(animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setSelected(_ filter: TaskFilter) {
        guard filter != selected else { return }
        selected = filter
        applySelection(animated: window != nil)
    }

    private func handleTap(_ filter: TaskFilter) {
        guard filter != selected else { return }
        selected = filter
        applySelection(animated: true)
        onSelectionChange?(filter)
    }

    private func applySelection(animated: Bool) {
        let apply = {
            self.buttons.forEach { filter, button in
                button.setExpanded(filter == self.selected)
            }
            self.layoutIfNeeded()
        }
        if animated {
            UIView.animate(
                withDuration: Constants.animationDuration,
                delay: 0,
                usingSpringWithDamping: 0.85,
                initialSpringVelocity: 0.4,
                options: [.curveEaseOut],
                animations: apply
            )
        } else {
            apply()
        }
    }
}

private final class CompactFilterButton: UIControl {

    private enum Constants {
        static let height: CGFloat = 36
        static let horizontalPadding: CGFloat = 10
        static let labelLeftPadding: CGFloat = 6
        static let symbolPointSize: CGFloat = 14
    }

    private let filter: TaskFilter

    private let iconView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.preferredSymbolConfiguration = UIImage.SymbolConfiguration(
            pointSize: Constants.symbolPointSize, weight: .semibold
        )
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .subheadline).withSemibold()
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    init(filter: TaskFilter) {
        self.filter = filter
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = Constants.height / 2
        layer.cornerCurve = .continuous
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)

        iconView.image = UIImage(systemName: filter.symbolName)
        titleLabel.text = filter.title

        addSubview(iconView)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Constants.height),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.horizontalPadding),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: Constants.symbolPointSize + 4),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: Constants.labelLeftPadding),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.horizontalPadding),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])

        accessibilityLabel = filter.title
        accessibilityTraits = .button

        setExpanded(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func setExpanded(_ selected: Bool) {
        backgroundColor = selected
            ? UIColor.systemBlue.withAlphaComponent(0.15)
            : UIColor.secondarySystemFill
        iconView.tintColor = selected ? .systemBlue : .secondaryLabel
        titleLabel.textColor = selected ? .systemBlue : .secondaryLabel
        accessibilityValue = selected ? "выбрано" : nil
        accessibilityTraits = selected ? [.button, .selected] : .button
    }
}

private extension UIFont {
    func withSemibold() -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: UIFont.Weight.semibold]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
