//
//  UpcomingTasksSectionView.swift
//  SmartPlanner
//

import UIKit

final class UpcomingTasksSectionView: UIView {

    var onSeeAll: (() -> Void)?
    var onToggle: ((Task.ID) -> Void)?
    var onSelect: ((Task.ID) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ближайшие задачи"
        label.font = UIFont.preferredFont(forTextStyle: .title3).withSemibold()
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let seeAllButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.title = "Смотреть все"
        config.contentInsets = .zero
        let button = UIButton(configuration: config)
        button.tintColor = .systemBlue
        return button
    }()

    private let cardStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let cardContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = DesignTokens.Palette.cardBackground
        view.layer.cornerRadius = DesignTokens.Radius.card
        view.layer.cornerCurve = .continuous
        return view
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false

        seeAllButton.addAction(UIAction { [weak self] _ in self?.onSeeAll?() }, for: .touchUpInside)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), seeAllButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center

        cardContainer.addSubview(cardStack)
        NSLayoutConstraint.activate([
            cardStack.topAnchor.constraint(equalTo: cardContainer.topAnchor, constant: DesignTokens.Spacing.s),
            cardStack.bottomAnchor.constraint(equalTo: cardContainer.bottomAnchor, constant: -DesignTokens.Spacing.s),
            cardStack.leadingAnchor.constraint(equalTo: cardContainer.leadingAnchor, constant: DesignTokens.Spacing.l),
            cardStack.trailingAnchor.constraint(equalTo: cardContainer.trailingAnchor, constant: -DesignTokens.Spacing.l)
        ])

        let main = UIStackView(arrangedSubviews: [headerStack, cardContainer])
        main.axis = .vertical
        main.spacing = DesignTokens.Spacing.m
        main.translatesAutoresizingMaskIntoConstraints = false
        addSubview(main)
        NSLayoutConstraint.activate([
            main.topAnchor.constraint(equalTo: topAnchor),
            main.leadingAnchor.constraint(equalTo: leadingAnchor),
            main.trailingAnchor.constraint(equalTo: trailingAnchor),
            main.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func update(tasks: [Task]) {
        cardStack.arrangedSubviews.forEach {
            cardStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        cardContainer.isHidden = tasks.isEmpty
        for (index, task) in tasks.enumerated() {
            let cell = UpcomingTaskCell()
            cell.configure(with: task)
            cell.onToggleCompleted = { [weak self] in self?.onToggle?(task.id) }
            cell.addAction(UIAction { [weak self] _ in self?.onSelect?(task.id) }, for: .touchUpInside)
            cardStack.addArrangedSubview(cell)
            if index < tasks.count - 1 {
                cardStack.addArrangedSubview(makeSeparator())
            }
        }
    }

    private func makeSeparator() -> UIView {
        let view = UIView()
        view.backgroundColor = DesignTokens.Palette.separator
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: DesignTokens.Sizing.separatorHeight).isActive = true
        return view
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
