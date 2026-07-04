//
//  StatisticsLegendView.swift
//  SmartPlanner
//

import UIKit

struct LegendItem {
    let title: String
    let value: Int
    let color: UIColor
}

final class StatisticsLegendView: UIStackView {

    private enum Constants {
        static let dotSize: CGFloat = 10
    }

    init() {
        super.init(frame: .zero)
        axis = .vertical
        spacing = DesignTokens.Spacing.s
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init(coder: NSCoder) { fatalError() }

    func update(items: [LegendItem]) {
        arrangedSubviews.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        items.forEach { addArrangedSubview(makeRow($0)) }
    }

    private func makeRow(_ item: LegendItem) -> UIView {
        let dot = UIView()
        dot.backgroundColor = item.color
        dot.layer.cornerRadius = Constants.dotSize / 2
        dot.layer.cornerCurve = .continuous
        dot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dot.widthAnchor.constraint(equalToConstant: Constants.dotSize),
            dot.heightAnchor.constraint(equalToConstant: Constants.dotSize)
        ])

        let titleLabel = UILabel()
        titleLabel.text = item.title
        titleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        titleLabel.textColor = .label
        titleLabel.adjustsFontForContentSizeCategory = true

        let valueLabel = UILabel()
        valueLabel.text = "\(item.value)"
        valueLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        valueLabel.textColor = .secondaryLabel
        valueLabel.adjustsFontForContentSizeCategory = true
        valueLabel.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [dot, titleLabel, valueLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.spacing = DesignTokens.Spacing.s
        row.isAccessibilityElement = true
        row.accessibilityLabel = "\(item.title): \(item.value)"
        return row
    }
}
