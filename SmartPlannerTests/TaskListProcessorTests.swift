//
//  TaskListProcessorTests.swift
//  SmartPlannerTests
//

import Testing
import Foundation
@testable import SmartPlanner

struct TaskListProcessorTests {

    private func makeTask(
        title: String,
        priority: TaskPriority = .medium,
        completed: Bool = false,
        deadline: Date? = nil,
        createdAt: Date = Date()
    ) -> Task {
        Task(title: title, priority: priority, isFlagged: false, deadline: deadline, isCompleted: completed, createdAt: createdAt)
    }

    @Test func filterAllReturnsAll() {
        let sut = TaskListProcessor()
        let tasks = [makeTask(title: "a"), makeTask(title: "b", completed: true)]
        #expect(sut.process(tasks, filter: .all, sort: .dateNewest).count == 2)
    }

    @Test func filterActiveExcludesCompleted() {
        let sut = TaskListProcessor()
        let tasks = [makeTask(title: "a"), makeTask(title: "b", completed: true)]
        let result = sut.process(tasks, filter: .active, sort: .dateNewest)
        #expect(result.map(\.title) == ["a"])
    }

    @Test func filterCompletedOnlyCompleted() {
        let sut = TaskListProcessor()
        let tasks = [makeTask(title: "a"), makeTask(title: "b", completed: true)]
        let result = sut.process(tasks, filter: .completed, sort: .dateNewest)
        #expect(result.map(\.title) == ["b"])
    }

    @Test func filterTodayMatchesSameCalendarDay() {
        let fixed = Date(timeIntervalSince1970: 1_750_000_000) // arbitrary
        let calendar = Calendar(identifier: .gregorian)
        let sut = TaskListProcessor(calendar: calendar, now: { fixed })
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: fixed)
        let tasks = [
            makeTask(title: "today", deadline: fixed),
            makeTask(title: "tomorrow", deadline: tomorrow),
            makeTask(title: "no-date")
        ]
        let result = sut.process(tasks, filter: .today, sort: .dateNewest)
        #expect(result.map(\.title) == ["today"])
    }

    @Test func sortPriorityHighFirst() {
        let sut = TaskListProcessor()
        let tasks = [
            makeTask(title: "low", priority: .low),
            makeTask(title: "high", priority: .high),
            makeTask(title: "med", priority: .medium)
        ]
        let result = sut.process(tasks, filter: .all, sort: .priorityHighFirst)
        #expect(result.map(\.title) == ["high", "med", "low"])
    }

    @Test func sortDateNewest() {
        let now = Date()
        let earlier = now.addingTimeInterval(-1000)
        let tasks = [
            makeTask(title: "old", createdAt: earlier),
            makeTask(title: "new", createdAt: now)
        ]
        let result = TaskListProcessor().process(tasks, filter: .all, sort: .dateNewest)
        #expect(result.map(\.title) == ["new", "old"])
    }
}

struct TaskCountFormatterTests {
    @Test func pluralization() {
        #expect(TaskCountFormatter.localize(count: 0) == "0 задач")
        #expect(TaskCountFormatter.localize(count: 1) == "1 задача")
        #expect(TaskCountFormatter.localize(count: 3) == "3 задачи")
        #expect(TaskCountFormatter.localize(count: 5) == "5 задач")
        #expect(TaskCountFormatter.localize(count: 11) == "11 задач")
        #expect(TaskCountFormatter.localize(count: 21) == "21 задача")
        #expect(TaskCountFormatter.localize(count: 22) == "22 задачи")
    }
}
