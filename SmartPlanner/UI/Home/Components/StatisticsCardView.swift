//
//  StatisticsCardView.swift
//  SmartPlanner
//

import UIKit

final class StatisticsCardView: UIView {

    var onPeriodChange: ((DashboardPeriod) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Статистика"
        label.font = UIFont.preferredFont(forTextStyle: .title3).withSemibold()
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let periodButton: UIButton = {
        var config = UIButton.Configuration.gray()
        config.cornerStyle = .capsule
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = DesignTokens.Spacing.xs
        config.buttonSize = .small
        let button = UIButton(configuration: config)
        button.showsMenuAsPrimaryAction = true
        return button
    }()

    let donut = StatisticsDonutChartView()
    let legend = StatisticsLegendView()

    private(set) var selectedPeriod: DashboardPeriod = .week

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DesignTokens.Palette.cardBackground
        layer.cornerRadius = DesignTokens.Radius.card
        layer.cornerCurve = .continuous

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), periodButton])
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = DesignTokens.Spacing.s

        let chartStack = UIStackView(arrangedSubviews: [donut, legend])
        chartStack.axis = .horizontal
        chartStack.alignment = .center
        chartStack.spacing = DesignTokens.Spacing.l
        chartStack.distribution = .fill

        let main = UIStackView(arrangedSubviews: [headerStack, chartStack])
        main.axis = .vertical
        main.spacing = DesignTokens.Spacing.l
        main.translatesAutoresizingMaskIntoConstraints = false
        addSubview(main)
        NSLayoutConstraint.activate([
            main.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.Spacing.l),
            main.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.Spacing.l),
            main.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.Spacing.l),
            main.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.Spacing.l)
        ])

        rebuildPeriodMenu()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func update(statistics: DashboardStatistics) {
        donut.update(
            total: statistics.total,
            segments: [
                DonutSegment(value: statistics.completed, color: DashboardPalette.completed),
                DonutSegment(value: statistics.active, color: DashboardPalette.active),
                DonutSegment(value: statistics.overdue, color: DashboardPalette.overdue),
                DonutSegment(value: statistics.withoutDate, color: DashboardPalette.noDate)
            ]
        )
        legend.update(items: [
            LegendItem(title: "Выполнено", value: statistics.completed, color: DashboardPalette.completed),
            LegendItem(title: "Активные", value: statistics.active, color: DashboardPalette.active),
            LegendItem(title: "Просрочено", value: statistics.overdue, color: DashboardPalette.overdue),
            LegendItem(title: "Без даты", value: statistics.withoutDate, color: DashboardPalette.noDate)
        ])
    }

    func setPeriod(_ period: DashboardPeriod) {
        selectedPeriod = period
        periodButton.configuration?.title = period.title
        rebuildPeriodMenu()
    }

    private func rebuildPeriodMenu() {
        let actions = DashboardPeriod.allCases.map { option in
            UIAction(
                title: option.title,
                image: UIImage(systemName: option.symbolName),
                state: option == selectedPeriod ? .on : .off
            ) { [weak self] _ in
                self?.onPeriodChange?(option)
            }
        }
        periodButton.menu = UIMenu(children: actions)
        periodButton.configuration?.title = selectedPeriod.title
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
