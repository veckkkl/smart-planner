//
//  Task.swift
//  SmartPlanner
//
//  Created by valentina balde on 11/30/25.
//
import Foundation

enum TaskPriority: Int, CaseIterable {
    case low = 0
    case medium = 1
    case high = 2

    var title: String {
        switch self {
        case .low: return "Низкий"
        case .medium: return "Средний"
        case .high: return "Высокий"
        }
    }
}

struct Task {
    let id: UUID
    let createdAt: Date
    var title: String
    var details: String?
    var priority: TaskPriority
    var isFlagged: Bool
    var deadline: Date?
    var isCompleted: Bool

    init(
        title: String,
        details: String? = nil,
        priority: TaskPriority,
        isFlagged: Bool,
        deadline: Date? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.createdAt = createdAt
        self.title = title
        self.details = details
        self.priority = priority
        self.isFlagged = isFlagged
        self.deadline = deadline
        self.isCompleted = isCompleted
    }
}
