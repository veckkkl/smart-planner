//
//  TasksViewModelXCTests.swift
//  SmartPlannerTests
//

import XCTest
@testable import SmartPlanner

final class TasksViewModelXCTests: XCTestCase {

    private let fixedNow = Date(timeIntervalSince1970: 1_750_000_000)

    func testStartLoadsTasksFromRepository() {
        let tasks = [
            makeTask(title: "first"),
            makeTask(title: "second")
        ]
        let repository = TasksViewModelRepositoryFake(tasks: tasks)
        let sut = makeSUT(repository: repository)
        var receivedSections: [TaskSectionResult] = []

        sut.onTasksChanged = { receivedSections = $0 }
        sut.start()

        XCTAssertEqual(sut.totalCount, 2)
        XCTAssertEqual(receivedSections.flatMap(\.tasks).map(\.title), ["first", "second"])
        sut.stop()
    }

    func testFilterAllShowsEveryTask() {
        let tasks = [
            makeTask(title: "active"),
            makeTask(title: "completed", isCompleted: true)
        ]
        let sut = makeStartedSUT(tasks: tasks)

        sut.updateFilter(.all)

        XCTAssertEqual(sut.filter, .all)
        XCTAssertEqual(sut.sections.flatMap(\.tasks).count, 2)
        sut.stop()
    }

    func testFilterTodayShowsOnlyTasksFromToday() {
        let tasks = [
            makeTask(title: "today", deadlineOffset: 60),
            makeTask(title: "tomorrow", deadlineOffset: 24 * 60 * 60),
            makeTask(title: "without date", deadlineOffset: nil)
        ]
        let sut = makeStartedSUT(tasks: tasks)

        sut.updateFilter(.today)

        XCTAssertEqual(sut.sections.flatMap(\.tasks).map(\.title), ["today"])
        sut.stop()
    }

    func testFilterUpcomingShowsOnlyFutureUncompletedTasks() {
        let tasks = [
            makeTask(title: "future", deadlineOffset: 60),
            makeTask(title: "past", deadlineOffset: -60),
            makeTask(title: "done", isCompleted: true, deadlineOffset: 60)
        ]
        let sut = makeStartedSUT(tasks: tasks)

        sut.updateFilter(.upcoming)

        XCTAssertEqual(sut.sections.flatMap(\.tasks).map(\.title), ["future"])
        sut.stop()
    }

    func testSortUpdatesVisibleOrder() {
        let tasks = [
            makeTask(title: "low", priority: .low),
            makeTask(title: "high", priority: .high),
            makeTask(title: "medium", priority: .medium)
        ]
        let sut = makeStartedSUT(tasks: tasks)

        sut.updateSort(.priorityHighFirst)

        XCTAssertEqual(sut.sortOption, .priorityHighFirst)
        XCTAssertEqual(sut.sections.flatMap(\.tasks).map(\.title), ["high", "medium", "low"])
        sut.stop()
    }

    func testToggleCompletionUpdatesRepository() throws {
        let task = makeTask(title: "task")
        let repository = TasksViewModelRepositoryFake(tasks: [task])
        let sut = makeStartedSUT(repository: repository)

        sut.toggleCompletion(taskID: task.id)

        let updated = try XCTUnwrap(repository.updatedTasks.first)
        XCTAssertEqual(updated.id, task.id)
        XCTAssertTrue(updated.isCompleted)
        sut.stop()
    }

    func testDeleteRemovesTaskThroughRepository() {
        let task = makeTask(title: "task")
        let repository = TasksViewModelRepositoryFake(tasks: [task])
        let sut = makeStartedSUT(repository: repository)

        sut.delete(taskID: task.id)

        XCTAssertEqual(repository.deletedIDs, [task.id])
        sut.stop()
    }

    func testEmptyStateWhenRepositoryHasNoTasks() {
        let sut = makeStartedSUT(tasks: [])

        XCTAssertFalse(sut.hasAnyTasks)
        XCTAssertEqual(sut.totalCount, 0)
        XCTAssertEqual(sut.sections.flatMap(\.tasks).count, 0)
        sut.stop()
    }

    private func makeStartedSUT(tasks: [Task]) -> TasksViewModel {
        makeStartedSUT(repository: TasksViewModelRepositoryFake(tasks: tasks))
    }

    private func makeStartedSUT(repository: TasksViewModelRepositoryFake) -> TasksViewModel {
        let sut = makeSUT(repository: repository)
        sut.start()
        return sut
    }

    private func makeSUT(repository: TasksViewModelRepositoryFake) -> TasksViewModel {
        TasksViewModel(
            repository: repository,
            processor: TaskListProcessor(calendar: Calendar(identifier: .gregorian), now: { self.fixedNow })
        )
    }

    private func makeTask(
        title: String,
        priority: TaskPriority = .medium,
        isCompleted: Bool = false,
        deadlineOffset: TimeInterval? = nil
    ) -> Task {
        Task(
            title: title,
            priority: priority,
            isFlagged: false,
            deadline: deadlineOffset.map { fixedNow.addingTimeInterval($0) },
            isCompleted: isCompleted,
            createdAt: fixedNow
        )
    }
}

private final class TasksViewModelRepositoryFake: TaskRepositoryProtocol {
    private var tasks: [Task]
    private var observers: [ObjectIdentifier: ([Task]) -> Void] = [:]

    private(set) var updatedTasks: [Task] = []
    private(set) var deletedIDs: [Task.ID] = []

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
        notify()
    }

    func delete(id: Task.ID) {
        deletedIDs.append(id)
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
