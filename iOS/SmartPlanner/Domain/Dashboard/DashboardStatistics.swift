//
//  DashboardStatistics.swift
//  SmartPlanner
//

import Foundation

struct DashboardStatistics: Equatable {
    let total: Int
    let completed: Int
    let active: Int
    let overdue: Int
    let withoutDate: Int
    let byPriority: [TaskPriority: Int]

    static let empty = DashboardStatistics(
        total: 0, completed: 0, active: 0, overdue: 0, withoutDate: 0,
        byPriority: [.low: 0, .medium: 0, .high: 0]
    )
}
