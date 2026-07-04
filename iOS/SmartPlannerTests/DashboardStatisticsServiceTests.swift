//
//  DashboardStatisticsServiceTests.swift
//  SmartPlannerTests
//

import Testing
import Foundation
@testable import SmartPlanner

struct DashboardStatisticsServiceTests {

    private let fixedNow = Date(timeIntervalSince1970: 1_750_000_000)

    private func service() -> DashboardStatisticsService {
        DashboardStatisticsService(calendar: Calendar(identifier: .gregorian), now: { self.fixedNow })
    }

    private func makeTask(
        title: String = "t",
        priority: TaskPriority = .medium,
        completed: Bool = false,
        deadlineOffset: TimeInterval? = nil,
        createdOffset: TimeInterval = 0
    ) -> Task {
        Task(
            title: title,
            priority: priority,
            isFlagged: false,
            deadline: deadlineOffset.map { fixedNow.addingTimeInterval($0) },
            isCompleted: completed,
            createdAt: fixedNow.addingTimeInterval(createdOffset)
        )
    }

    @Test func emptyStatisticsForEmptyInput() {
        let stats = service().statistics(for: [], period: .allTime)
        #expect(stats == .empty)
    }

    @Test func statisticsClassifiesCompletedActiveOverdueNoDate() {
        let tasks = [
            makeTask(title: "done", completed: true, deadlineOffset: -1000),
            makeTask(title: "overdue", deadlineOffset: -100),
            makeTask(title: "future", deadlineOffset: 1000),
            makeTask(title: "no-date")
        ]
        let stats = service().statistics(for: tasks, period: .allTime)
        #expect(stats.total == 4)
        #expect(stats.completed == 1)
        #expect(stats.active == 1)
        #expect(stats.overdue == 1)
        #expect(stats.withoutDate == 1)
        #expect(stats.completed + stats.active + stats.overdue + stats.withoutDate == stats.total)
    }

    @Test func upcomingExcludesCompletedAndPastAndSortsByDeadline() {
        let tasks = [
            makeTask(title: "past", deadlineOffset: -10),
            makeTask(title: "soon", deadlineOffset: 100),
            makeTask(title: "later", deadlineOffset: 500),
            makeTask(title: "done", completed: true, deadlineOffset: 50)
        ]
        let result = service().upcoming(from: tasks, limit: 5)
        #expect(result.map(\.title) == ["soon", "later"])
    }

    @Test func tasksOnDayMatchesSameCalendarDay() {
        let calendar = Calendar(identifier: .gregorian)
        let sut = service()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: fixedNow) ?? fixedNow
        let tasks = [
            makeTask(title: "today", deadlineOffset: 60),
            makeTask(title: "tomorrow", deadlineOffset: 60 * 60 * 24 + 60)
        ]
        let result = sut.tasks(on: tomorrow, from: tasks)
        #expect(result.map(\.title) == ["tomorrow"])
    }

    @Test func tasksByDayGroupsByStartOfDay() {
        let sut = service()
        let tasks = [
            makeTask(title: "a", deadlineOffset: 60),
            makeTask(title: "b", deadlineOffset: 120),
            makeTask(title: "no-date")
        ]
        let result = sut.tasksByDay(tasks)
        #expect(result.values.flatMap { $0 }.count == 2)
    }

    @Test func periodFilteringByMonthScopesByCreatedAtWhenNoDeadline() {
        let sut = service()
        let recent = makeTask(title: "recent")
        let oldCreated = fixedNow.addingTimeInterval(-60 * 60 * 24 * 90)
        let old = Task(title: "old", priority: .low, isFlagged: false, deadline: nil, isCompleted: false, createdAt: oldCreated)
        let stats = sut.statistics(for: [recent, old], period: .month)
        #expect(stats.total == 1)
    }

    @Test func weekPeriodExcludesOverdueOlderThanWeek() {
        let sut = service()
        let twoMonthsAgo: TimeInterval = -60 * 60 * 24 * 60
        let oldOverdue = Task(
            title: "ancient-overdue",
            priority: .high,
            isFlagged: false,
            deadline: fixedNow.addingTimeInterval(twoMonthsAgo),
            isCompleted: false,
            createdAt: fixedNow.addingTimeInterval(twoMonthsAgo)
        )
        let stats = sut.statistics(for: [oldOverdue], period: .week)
        #expect(stats.total == 0)
        #expect(stats.overdue == 0)
    }

    @Test func monthPeriodExcludesOverdueOlderThanMonth() {
        let sut = service()
        let sixMonthsAgo: TimeInterval = -60 * 60 * 24 * 180
        let oldOverdue = Task(
            title: "ancient-overdue",
            priority: .high,
            isFlagged: false,
            deadline: fixedNow.addingTimeInterval(sixMonthsAgo),
            isCompleted: false,
            createdAt: fixedNow.addingTimeInterval(sixMonthsAgo)
        )
        let stats = sut.statistics(for: [oldOverdue], period: .month)
        #expect(stats.total == 0)
        #expect(stats.overdue == 0)
    }

    @Test func weekPeriodIncludesTaskWithDeadlineInThisWeekEvenIfCreatedLongAgo() {
        let sut = service()
        let oldCreated = fixedNow.addingTimeInterval(-60 * 60 * 24 * 60)
        let task = Task(
            title: "planned",
            priority: .medium,
            isFlagged: false,
            deadline: fixedNow.addingTimeInterval(60 * 60),
            isCompleted: false,
            createdAt: oldCreated
        )
        let stats = sut.statistics(for: [task], period: .week)
        #expect(stats.total == 1)
        #expect(stats.active == 1)
    }

    @Test func weekPeriodCountsOverdueOnlyWhenDeadlineIsWithinWeek() {
        let sut = service()
        let twoHoursAgo: TimeInterval = -60 * 60 * 2
        let lastMonth: TimeInterval = -60 * 60 * 24 * 45
        let recentOverdue = Task(
            title: "recent-overdue",
            priority: .high,
            isFlagged: false,
            deadline: fixedNow.addingTimeInterval(twoHoursAgo),
            isCompleted: false,
            createdAt: fixedNow.addingTimeInterval(twoHoursAgo)
        )
        let oldOverdue = Task(
            title: "old-overdue",
            priority: .high,
            isFlagged: false,
            deadline: fixedNow.addingTimeInterval(lastMonth),
            isCompleted: false,
            createdAt: fixedNow.addingTimeInterval(lastMonth)
        )
        let stats = sut.statistics(for: [recentOverdue, oldOverdue], period: .week)
        #expect(stats.total == 1)
        #expect(stats.overdue == 1)
    }
}
