//
//  DayTasksViewModelTests.swift
//  SmartPlannerTests
//

import Testing
import Foundation
@testable import SmartPlanner

struct DayTasksViewModelTests {

    private let calendar = Calendar(identifier: .gregorian)

    private func makeDate(day: Int, hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 6, day: day, hour: hour)) ?? Date(timeIntervalSince1970: 0)
    }

    private func makeTask(
        title: String,
        day: Int,
        hour: Int = 12,
        isCompleted: Bool = false
    ) -> Task {
        Task(
            title: title,
            priority: .medium,
            isFlagged: false,
            deadline: makeDate(day: day, hour: hour),
            isCompleted: isCompleted,
            createdAt: makeDate(day: day, hour: hour)
        )
    }

    @Test func loadsTasksForSelectedDay() {
        let today = makeTask(title: "today", day: 16)
        let repository = FakeTaskRepository(tasks: [today])
        let sut = makeSUT(day: makeDate(day: 16), repository: repository)

        sut.start()

        #expect(sut.state.tasks.map(\.title) == ["today"])
        sut.stop()
    }

    @Test func showsEmptyStateWhenThereAreNoTasks() {
        let repository = FakeTaskRepository(tasks: [])
        let sut = makeSUT(day: makeDate(day: 16), repository: repository)

        sut.start()

        #expect(sut.state.isEmpty)
        #expect(sut.state.tasks.isEmpty)
        sut.stop()
    }

    @Test func toggleCompletionUpdatesTaskThroughRepository() {
        let task = makeTask(title: "today", day: 16)
        let repository = FakeTaskRepository(tasks: [task])
        let sut = makeSUT(day: makeDate(day: 16), repository: repository)

        sut.start()
        sut.toggleCompletion(taskID: task.id)

        #expect(repository.updatedTasks.count == 1)
        #expect(repository.updatedTasks.first?.id == task.id)
        #expect(repository.updatedTasks.first?.isCompleted == true)
        sut.stop()
    }

    @Test func toggleCompletionRefreshesVisibleTasks() {
        let task = makeTask(title: "today", day: 16)
        let repository = FakeTaskRepository(tasks: [task])
        let sut = makeSUT(day: makeDate(day: 16), repository: repository)

        sut.start()
        sut.toggleCompletion(taskID: task.id)

        #expect(sut.state.tasks.first?.id == task.id)
        #expect(sut.state.tasks.first?.isCompleted == true)
        sut.stop()
    }

    @Test func excludesTasksFromOtherDays() {
        let today = makeTask(title: "today", day: 16)
        let tomorrow = makeTask(title: "tomorrow", day: 17)
        let repository = FakeTaskRepository(tasks: [today, tomorrow])
        let sut = makeSUT(day: makeDate(day: 16), repository: repository)

        sut.start()

        #expect(sut.state.tasks.map(\.title) == ["today"])
        sut.stop()
    }

    private func makeSUT(day: Date, repository: FakeTaskRepository) -> DayTasksViewModel {
        DayTasksViewModel(
            day: day,
            repository: repository,
            service: DashboardStatisticsService(calendar: calendar)
        )
    }
}

private final class FakeTaskRepository: TaskRepositoryProtocol {
    private var tasks: [Task]
    private var observers: [ObjectIdentifier: ([Task]) -> Void] = [:]

    private(set) var updatedTasks: [Task] = []

    init(tasks: [Task]) {
        self.tasks = tasks
    }

    func save(_ task: Task) {
        tasks.append(task)
        notify()
    }

    func update(_ task: Task) {
        updatedTasks.append(task)
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index] = task
        }
    }

    func delete(id: Task.ID) {
        tasks.removeAll { $0.id == id }
        notify()
    }

    func fetchAll() -> [Task] {
        tasks
    }

    func addObserver(_ observer: AnyObject, onChange: @escaping ([Task]) -> Void) {
        observers[ObjectIdentifier(observer)] = onChange
        onChange(tasks)
    }

    func removeObserver(_ observer: AnyObject) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
    }

    private func notify() {
        observers.values.forEach { $0(tasks) }
    }
}
