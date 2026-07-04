//
//  TaskFilter.swift
//  SmartPlanner
//

import Foundation

enum TaskFilter: Int, CaseIterable {
    case all
    case today
    case upcoming

    var title: String {
        switch self {
        case .all: return "Все"
        case .today: return "Сегодня"
        case .upcoming: return "Ближайшие"
        }
    }

    var symbolName: String {
        switch self {
        case .all: return "tray"
        case .today: return "sun.max"
        case .upcoming: return "calendar"
        }
    }
}

enum TaskListSection: Hashable {
    case flat
    case thisWeek
    case thisMonth

    var title: String {
        switch self {
        case .flat: return ""
        case .thisWeek: return "Эта неделя"
        case .thisMonth: return "Этот месяц"
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
