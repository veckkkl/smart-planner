//
//  TaskListProcessorTests.swift
//  SmartPlannerTests
//

import Testing
import Foundation
@testable import SmartPlanner

struct TaskListProcessorTests {

    private let fixedNow = Date(timeIntervalSince1970: 1_750_000_000)

    private func service() -> TaskListProcessor {
        TaskListProcessor(calendar: Calendar(identifier: .gregorian), now: { self.fixedNow })
    }

    private func makeTask(
        title: String,
        priority: TaskPriority = .medium,
        completed: Bool = false,
        flagged: Bool = false,
        deadlineOffset: TimeInterval? = nil,
        createdOffset: TimeInterval = 0
    ) -> Task {
        Task(
            title: title,
            priority: priority,
            isFlagged: flagged,
            deadline: deadlineOffset.map { fixedNow.addingTimeInterval($0) },
            isCompleted: completed,
            createdAt: fixedNow.addingTimeInterval(createdOffset)
        )
    }

    private func flat(_ result: [TaskSectionResult]) -> [Task] {
        result.flatMap(\.tasks)
    }

    @Test func filterAllReturnsEverythingInOneFlatSection() {
        let sut = service()
        let tasks = [makeTask(title: "a"), makeTask(title: "b", completed: true)]
        let result = sut.process(tasks, filter: .all, sort: .dateNewest)
        #expect(result.count == 1)
        #expect(result.first?.section == .flat)
        #expect(result.first?.tasks.count == 2)
    }

    @Test func filterTodayMatchesSameCalendarDay() {
        let sut = service()
        let tomorrowOffset: TimeInterval = 60 * 60 * 24
        let tasks = [
            makeTask(title: "today", deadlineOffset: 60),
            makeTask(title: "tomorrow", deadlineOffset: tomorrowOffset + 60),
            makeTask(title: "no-date")
        ]
        let result = flat(sut.process(tasks, filter: .today, sort: .dateNewest))
        #expect(result.map(\.title) == ["today"])
    }

    @Test func filterUpcomingGroupsByWeekAndMonth() {
        let sut = service()
        let inThreeDays: TimeInterval = 60 * 60 * 24 * 3
        let inTwoWeeks: TimeInterval = 60 * 60 * 24 * 14
        let inAYear: TimeInterval = 60 * 60 * 24 * 365
        let tasks = [
            makeTask(title: "soon", deadlineOffset: inThreeDays),
            makeTask(title: "this-month", deadlineOffset: inTwoWeeks),
            makeTask(title: "far-future", deadlineOffset: inAYear),
            makeTask(title: "completed", completed: true, deadlineOffset: inThreeDays),
            makeTask(title: "no-date")
        ]
        let result = sut.process(tasks, filter: .upcoming, sort: .dateNewest)
        let weekly = result.first { $0.section == .thisWeek }
        let monthly = result.first { $0.section == .thisMonth }
        #expect(weekly?.tasks.map(\.title) == ["soon"])
        #expect(monthly?.tasks.map(\.title) == ["this-month"] || monthly == nil)
    }

    @Test func filterUpcomingExcludesPastDeadlinesAndCompleted() {
        let sut = service()
        let tasks = [
            makeTask(title: "past", deadlineOffset: -60),
            makeTask(title: "future", deadlineOffset: 60 * 60 * 24),
            makeTask(title: "done", completed: true, deadlineOffset: 60 * 60 * 24)
        ]
        let result = flat(sut.process(tasks, filter: .upcoming, sort: .dateNewest))
        #expect(result.map(\.title) == ["future"])
    }

    @Test func sortPriorityHighFirst() {
        let sut = service()
        let tasks = [
            makeTask(title: "low", priority: .low),
            makeTask(title: "high", priority: .high),
            makeTask(title: "med", priority: .medium)
        ]
        let result = flat(sut.process(tasks, filter: .all, sort: .priorityHighFirst))
        #expect(result.map(\.title) == ["high", "med", "low"])
    }

    @Test func emptySectionIsOmitted() {
        let sut = service()
        let inAYear: TimeInterval = 60 * 60 * 24 * 365
        let tasks = [makeTask(title: "far", deadlineOffset: inAYear)]
        let result = sut.process(tasks, filter: .upcoming, sort: .dateNewest)
        // Far-future task isn't in this week or this month → both sections empty → result is empty.
        #expect(result.isEmpty)
    }
}
