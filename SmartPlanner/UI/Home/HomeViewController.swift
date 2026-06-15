//
//  HomeViewController.swift
//  SmartPlanner
//

import UIKit

final class HomeViewController: UIViewController {

    private enum Strings {
        static let screenTitle = "Главная"
    }

    private let viewModel: DashboardViewModel

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = DesignTokens.Spacing.l
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let statisticsCard = StatisticsCardView()
    private let calendarCard = TasksCalendarView()
    private let upcomingSection = UpcomingTasksSectionView()
    private let emptyView = EmptyDashboardView()

    init(viewModel: DashboardViewModel = DashboardViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = Strings.screenTitle
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic

        setupLayout()
        bindViewModel()
        viewModel.start()
    }

    deinit { viewModel.stop() }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        view.addSubview(emptyView)
        emptyView.translatesAutoresizingMaskIntoConstraints = false

        [statisticsCard, calendarCard, upcomingSection].forEach { contentStack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: DesignTokens.Spacing.l),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: DesignTokens.Spacing.l),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -DesignTokens.Spacing.l),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -DesignTokens.Spacing.xxl),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -DesignTokens.Spacing.l * 2),

            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        statisticsCard.setPeriod(viewModel.period)
        statisticsCard.onPeriodChange = { [weak self] period in
            guard let self else { return }
            self.viewModel.setPeriod(period)
            self.statisticsCard.setPeriod(period)
        }

        calendarCard.delegate = self

        upcomingSection.onSeeAll = { [weak self] in self?.switchToTasksTab() }
        upcomingSection.onSelect = { [weak self] _ in self?.switchToTasksTab() }
        upcomingSection.onToggle = { [weak self] id in self?.viewModel.toggleCompletion(taskID: id) }

        emptyView.onCreateTapped = { [weak self] in self?.presentCreateTask() }
    }

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] in self?.render() }
    }

    private func render() {
        let hasTasks = viewModel.hasAnyTasks
        scrollView.isHidden = !hasTasks
        emptyView.isHidden = hasTasks

        guard hasTasks else { return }
        statisticsCard.update(statistics: viewModel.statistics)
        upcomingSection.update(tasks: viewModel.upcoming)
        calendarCard.reloadDecorations()
    }

    private func switchToTasksTab() {
        tabBarController?.selectedIndex = 2
    }

    private func presentCreateTask() {
        let createVC = CreateTaskViewController()
        navigationController?.pushViewController(createVC, animated: true)
    }
}

extension HomeViewController: TasksCalendarViewDelegate {
    func tasksCalendarView(_ view: TasksCalendarView, didSelect day: Date) {
        let tasks = viewModel.tasks(on: day)
        let detail = DayTasksViewController(day: day, tasks: tasks)
        navigationController?.pushViewController(detail, animated: true)
    }

    func tasksCalendarView(_ view: TasksCalendarView, markerFor day: Date) -> DayMarker? {
        viewModel.marker(for: day)
    }
}
