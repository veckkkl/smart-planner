//
//  DashboardViewModel.swift
//  SmartPlanner
//

import Foundation

struct DayMarker: Equatable {
    let hasActive: Bool
    let hasCompleted: Bool
    let hasOverdue: Bool
}

final class DashboardViewModel {

    enum Constants {
        static let upcomingLimit = 5
    }

    var onStateChanged: (() -> Void)?

    private(set) var statistics: DashboardStatistics = .empty
    private(set) var upcoming: [Task] = []
    private(set) var hasAnyTasks: Bool = false
    private(set) var period: DashboardPeriod = .week

    private let repository: TaskRepositoryProtocol
    private let service: DashboardStatisticsServicing
    private let calendar: Calendar
    private let now: () -> Date
    private var allTasks: [Task] = []
    private var tasksByDay: [Date: [Task]] = [:]

    init(
        repository: TaskRepositoryProtocol = InMemoryTaskRepository.shared,
        service: DashboardStatisticsServicing = DashboardStatisticsService(),
        calendar: Calendar = .current,
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.service = service
        self.calendar = calendar
        self.now = now
    }

    func start() {
        repository.addObserver(self) { [weak self] tasks in
            self?.process(tasks)
        }
    }

    func stop() {
        repository.removeObserver(self)
    }

    func setPeriod(_ value: DashboardPeriod) {
        period = value
        recompute()
    }

    func tasks(on day: Date) -> [Task] {
        service.tasks(on: day, from: allTasks)
    }

    func marker(for day: Date) -> DayMarker? {
        let key = calendar.startOfDay(for: day)
        guard let tasks = tasksByDay[key], !tasks.isEmpty else { return nil }
        let reference = now()
        var hasActive = false
        var hasCompleted = false
        var hasOverdue = false
        for task in tasks {
            if task.isCompleted {
                hasCompleted = true
            } else if let deadline = task.deadline, deadline < reference {
                hasOverdue = true
            } else {
                hasActive = true
            }
        }
        return DayMarker(hasActive: hasActive, hasCompleted: hasCompleted, hasOverdue: hasOverdue)
    }

    func toggleCompletion(taskID: Task.ID) {
        guard var task = allTasks.first(where: { $0.id == taskID }) else { return }
        task.isCompleted.toggle()
        repository.update(task)
    }

    private func process(_ tasks: [Task]) {
        allTasks = tasks
        tasksByDay = service.tasksByDay(tasks)
        recompute()
    }

    private func recompute() {
        hasAnyTasks = !allTasks.isEmpty
        statistics = service.statistics(for: allTasks, period: period)
        upcoming = service.upcoming(from: allTasks, limit: Constants.upcomingLimit)
        onStateChanged?()
    }
}
