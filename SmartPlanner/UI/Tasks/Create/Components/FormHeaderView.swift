//
//  FormHeaderView.swift
//  SmartPlanner
//

import UIKit

final class FormHeaderView: UIStackView {

    private let iconView: UIImageView = {
        let view = UIImageView()
        view.tintColor = DesignTokens.Palette.accent
        view.contentMode = .scaleAspectFit
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setContentHuggingPriority(.required, for: .horizontal)
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.cardTitle()
        label.textColor = DesignTokens.Palette.primaryText
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    let trailingLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.caption()
        label.textColor = DesignTokens.Palette.secondaryText
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .right
        return label
    }()

    init(symbolName: String, title: String, showsTrailingLabel: Bool) {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .center
        spacing = DesignTokens.Spacing.s
        translatesAutoresizingMaskIntoConstraints = false

        iconView.image = UIImage(systemName: symbolName)
        titleLabel.text = title

        addArrangedSubview(iconView)
        addArrangedSubview(titleLabel)
        if showsTrailingLabel {
            addArrangedSubview(trailingLabel)
        }

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: DesignTokens.Sizing.iconSize),
            iconView.heightAnchor.constraint(equalToConstant: DesignTokens.Sizing.iconSize)
        ])
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }
}
