//
//  TaskListProcessor.swift
//  SmartPlanner
//

import Foundation

struct TaskSectionResult: Equatable {
    let section: TaskListSection
    let tasks: [Task]
}

protocol TaskListProcessing {
    func process(_ tasks: [Task], filter: TaskFilter, sort: TaskSortOption) -> [TaskSectionResult]
}

struct TaskListProcessor: TaskListProcessing {

    private enum Constants {
        static let weekHorizonDays = 7
    }

    private let calendar: Calendar
    private let now: () -> Date

    init(calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.calendar = calendar
        self.now = now
    }

    func process(_ tasks: [Task], filter: TaskFilter, sort: TaskSortOption) -> [TaskSectionResult] {
        let prefiltered = applyPrimary(tasks, filter: filter)
        switch filter {
        case .upcoming:
            return groupedUpcoming(prefiltered, sort: sort)
        case .all, .today:
            return [TaskSectionResult(section: .flat, tasks: sorted(prefiltered, sort: sort))]
        }
    }

    private func applyPrimary(_ tasks: [Task], filter: TaskFilter) -> [Task] {
        switch filter {
        case .all:
            return tasks
        case .today:
            let today = now()
            return tasks.filter { task in
                guard let deadline = task.deadline else { return false }
                return calendar.isDate(deadline, inSameDayAs: today)
            }
        case .upcoming:
            let reference = now()
            return tasks.filter { task in
                guard !task.isCompleted, let deadline = task.deadline else { return false }
                return deadline >= reference
            }
        }
    }

    private func groupedUpcoming(_ tasks: [Task], sort: TaskSortOption) -> [TaskSectionResult] {
        let reference = now()
        guard
            let weekEnd = calendar.date(byAdding: .day, value: Constants.weekHorizonDays, to: reference),
            let monthInterval = calendar.dateInterval(of: .month, for: reference)
        else {
            return [TaskSectionResult(section: .flat, tasks: sorted(tasks, sort: sort))]
        }

        var weekly: [Task] = []
        var monthly: [Task] = []

        for task in tasks {
            guard let deadline = task.deadline else { continue }
            if deadline <= weekEnd {
                weekly.append(task)
            } else if monthInterval.contains(deadline) {
                monthly.append(task)
            }
        }

        var results: [TaskSectionResult] = []
        if !weekly.isEmpty {
            results.append(TaskSectionResult(section: .thisWeek, tasks: sorted(weekly, sort: sort)))
        }
        if !monthly.isEmpty {
            results.append(TaskSectionResult(section: .thisMonth, tasks: sorted(monthly, sort: sort)))
        }
        return results
    }

    private func sorted(_ tasks: [Task], sort: TaskSortOption) -> [Task] {
        switch sort {
        case .dateNewest:
            return tasks.sorted { deadlineOrCreatedAt($0) > deadlineOrCreatedAt($1) }
        case .dateOldest:
            return tasks.sorted { deadlineOrCreatedAt($0) < deadlineOrCreatedAt($1) }
        case .priorityHighFirst:
            return tasks.sorted { $0.priority.rawValue > $1.priority.rawValue }
        case .priorityLowFirst:
            return tasks.sorted { $0.priority.rawValue < $1.priority.rawValue }
        }
    }

    private func deadlineOrCreatedAt(_ task: Task) -> Date {
        task.deadline ?? task.createdAt
    }
}
