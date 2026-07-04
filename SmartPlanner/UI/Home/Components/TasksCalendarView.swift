//
//  TasksCalendarView.swift
//  SmartPlanner
//

import UIKit

protocol TasksCalendarViewDelegate: AnyObject {
    func tasksCalendarView(_ view: TasksCalendarView, didSelect day: Date)
    func tasksCalendarView(_ view: TasksCalendarView, markerFor day: Date) -> DayMarker?
}

final class TasksCalendarView: UIView {

    weak var delegate: TasksCalendarViewDelegate?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Календарь"
        label.font = UIFont.preferredFont(forTextStyle: .title3).withWeight(.semibold)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let calendarView: UICalendarView = {
        let view = UICalendarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.tintColor = .systemBlue
        return view
    }()

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = DesignTokens.Palette.cardBackground
        layer.cornerRadius = DesignTokens.Radius.card
        layer.cornerCurve = .continuous

        calendarView.delegate = self
        calendarView.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)

        let stack = UIStackView(arrangedSubviews: [titleLabel, calendarView])
        stack.axis = .vertical
        stack.spacing = DesignTokens.Spacing.s
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: DesignTokens.Spacing.l),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DesignTokens.Spacing.l),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DesignTokens.Spacing.l),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DesignTokens.Spacing.l)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    func reloadDecorations() {
        let visibleMonth = calendarView.visibleDateComponents
        let calendar = visibleMonth.calendar ?? .current
        guard
            let year = visibleMonth.year,
            let month = visibleMonth.month,
            let interval = calendar.dateInterval(
                of: .month,
                for: calendar.date(from: DateComponents(year: year, month: month, day: 1)) ?? Date()
            )
        else { return }

        var components: [DateComponents] = []
        var day = interval.start
        while day < interval.end {
            components.append(calendar.dateComponents([.year, .month, .day], from: day))
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? interval.end
        }
        calendarView.reloadDecorations(forDateComponents: components, animated: true)
    }
}

extension TasksCalendarView: UICalendarViewDelegate {
    func calendarView(
        _ calendarView: UICalendarView,
        decorationFor dateComponents: DateComponents
    ) -> UICalendarView.Decoration? {
        guard
            let date = dateComponents.calendar?.date(from: dateComponents) ?? Calendar.current.date(from: dateComponents),
            let marker = delegate?.tasksCalendarView(self, markerFor: date)
        else { return nil }
        return .customView { CalendarDotMarkerView(marker: marker) }
    }
}

extension TasksCalendarView: UICalendarSelectionSingleDateDelegate {
    func dateSelection(
        _ selection: UICalendarSelectionSingleDate,
        didSelectDate dateComponents: DateComponents?
    ) {
        guard
            let dateComponents,
            let date = dateComponents.calendar?.date(from: dateComponents) ?? Calendar.current.date(from: dateComponents)
        else { return }
        delegate?.tasksCalendarView(self, didSelect: date)
        selection.setSelected(nil, animated: true)
    }
}

private final class CalendarDotMarkerView: UIView {

    private enum Constants {
        static let dotSize: CGFloat = 4
        static let spacing: CGFloat = 2
    }

    init(marker: DayMarker) {
        super.init(frame: .zero)
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = Constants.spacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        if marker.hasCompleted { stack.addArrangedSubview(makeDot(color: DashboardPalette.completed)) }
        if marker.hasActive { stack.addArrangedSubview(makeDot(color: DashboardPalette.active)) }
        if marker.hasOverdue { stack.addArrangedSubview(makeDot(color: DashboardPalette.overdue)) }

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func makeDot(color: UIColor) -> UIView {
        let view = UIView()
        view.backgroundColor = color
        view.layer.cornerRadius = Constants.dotSize / 2
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: Constants.dotSize),
            view.heightAnchor.constraint(equalToConstant: Constants.dotSize)
        ])
        return view
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
