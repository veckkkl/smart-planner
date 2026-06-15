//
//  TaskListProcessor.swift
//  SmartPlanner
//

import Foundation

protocol TaskListProcessing {
    func process(_ tasks: [Task], filter: TaskFilter, sort: TaskSortOption) -> [Task]
}

struct TaskListProcessor: TaskListProcessing {

    private let calendar: Calendar
    private let now: () -> Date

    init(calendar: Calendar = .current, now: @escaping () -> Date = Date.init) {
        self.calendar = calendar
        self.now = now
    }

    func process(_ tasks: [Task], filter: TaskFilter, sort: TaskSortOption) -> [Task] {
        sorted(filtered(tasks, filter: filter), sort: sort)
    }

    private func filtered(_ tasks: [Task], filter: TaskFilter) -> [Task] {
        switch filter {
        case .all:
            return tasks
        case .active:
            return tasks.filter { !$0.isCompleted }
        case .completed:
            return tasks.filter { $0.isCompleted }
        case .today:
            let today = now()
            return tasks.filter { task in
                guard let deadline = task.deadline else { return false }
                return calendar.isDate(deadline, inSameDayAs: today)
            }
        }
    }

    private func sorted(_ tasks: [Task], sort: TaskSortOption) -> [Task] {
        switch sort {
        case .dateNewest:
            return tasks.sorted { $0.createdAt > $1.createdAt }
        case .dateOldest:
            return tasks.sorted { $0.createdAt < $1.createdAt }
        case .priorityHighFirst:
            return tasks.sorted { $0.priority.rawValue > $1.priority.rawValue }
        case .priorityLowFirst:
            return tasks.sorted { $0.priority.rawValue < $1.priority.rawValue }
        }
    }
}
