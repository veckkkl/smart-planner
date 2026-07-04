//
//  DashboardStatisticsService.swift
//  SmartPlanner
//

import Foundation

protocol DashboardStatisticsServicing {
    func statistics(for tasks: [Task], period: DashboardPeriod) -> DashboardStatistics
    func upcoming(from tasks: [Task], limit: Int) -> [Task]
    func tasksByDay(_ tasks: [Task]) -> [Date: [Task]]
    func tasks(on day: Date, from tasks: [Task]) -> [Task]
}

struct DashboardStatisticsService: DashboardStatisticsServicing {

    private let calendar: Calendar
    private let now: () -> Date

    init(calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.calendar = calendar
        self.now = now
    }

    func statistics(for tasks: [Task], period: DashboardPeriod) -> DashboardStatistics {
        let scoped = tasks.filter { isInPeriod($0, period: period) }
        let reference = now()

        var completed = 0
        var overdue = 0
        var activeWithFutureDate = 0
        var noDate = 0
        var byPriority: [TaskPriority: Int] = [.low: 0, .medium: 0, .high: 0]

        for task in scoped {
            byPriority[task.priority, default: 0] += 1

            if task.isCompleted {
                completed += 1
                continue
            }
            guard let deadline = task.deadline else {
                noDate += 1
                continue
            }
            if deadline < reference {
                overdue += 1
            } else {
                activeWithFutureDate += 1
            }
        }

        return DashboardStatistics(
            total: scoped.count,
            completed: completed,
            active: activeWithFutureDate,
            overdue: overdue,
            withoutDate: noDate,
            byPriority: byPriority
        )
    }

    func upcoming(from tasks: [Task], limit: Int) -> [Task] {
        let reference = now()
        return tasks
            .filter { !$0.isCompleted }
            .filter { ($0.deadline ?? reference) >= reference }
            .sorted { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }
            .prefix(limit)
            .map { $0 }
    }

    func tasksByDay(_ tasks: [Task]) -> [Date: [Task]] {
        var result: [Date: [Task]] = [:]
        for task in tasks {
            guard let deadline = task.deadline else { continue }
            let day = calendar.startOfDay(for: deadline)
            result[day, default: []].append(task)
        }
        return result
    }

    func tasks(on day: Date, from tasks: [Task]) -> [Task] {
        let target = calendar.startOfDay(for: day)
        return tasks.filter { task in
            guard let deadline = task.deadline else { return false }
            return calendar.startOfDay(for: deadline) == target
        }
    }

    private func isInPeriod(_ task: Task, period: DashboardPeriod) -> Bool {
        switch period {
        case .allTime:
            return true
        case .week:
            return isDate(referenceDate(for: task), inSamePeriodAs: now(), granularity: .weekOfYear)
        case .month:
            return isDate(referenceDate(for: task), inSamePeriodAs: now(), granularity: .month)
        }
    }

    private func referenceDate(for task: Task) -> Date {
        task.deadline ?? task.createdAt
    }

    private func isDate(_ lhs: Date, inSamePeriodAs rhs: Date, granularity: Calendar.Component) -> Bool {
        calendar.isDate(lhs, equalTo: rhs, toGranularity: granularity)
    }
}
