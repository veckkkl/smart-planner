//
//  DashboardPeriod.swift
//  SmartPlanner
//

import Foundation

enum DashboardPeriod: Int, CaseIterable {
    case week
    case month
    case allTime

    var title: String {
        switch self {
        case .week: return "Эта неделя"
        case .month: return "Этот месяц"
        case .allTime: return "Всё время"
        }
    }

    var symbolName: String {
        switch self {
        case .week: return "calendar.badge.clock"
        case .month: return "calendar"
        case .allTime: return "infinity"
        }
    }
}
