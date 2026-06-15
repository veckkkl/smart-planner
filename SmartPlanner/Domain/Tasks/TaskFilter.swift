//
//  TaskFilter.swift
//  SmartPlanner
//

import Foundation

enum TaskFilter: Int, CaseIterable {
    case all
    case active
    case completed
    case today

    var title: String {
        switch self {
        case .all: return "Все"
        case .active: return "Активные"
        case .completed: return "Выполненные"
        case .today: return "Сегодня"
        }
    }
}

enum TaskSortOption: Int, CaseIterable {
    case dateNewest
    case dateOldest
    case priorityHighFirst
    case priorityLowFirst

    var title: String {
        switch self {
        case .dateNewest: return "Сначала новые"
        case .dateOldest: return "Сначала старые"
        case .priorityHighFirst: return "Сначала сложные"
        case .priorityLowFirst: return "Сначала лёгкие"
        }
    }

    var symbolName: String {
        switch self {
        case .dateNewest, .dateOldest: return "calendar"
        case .priorityHighFirst, .priorityLowFirst: return "flag.checkered"
        }
    }
}
