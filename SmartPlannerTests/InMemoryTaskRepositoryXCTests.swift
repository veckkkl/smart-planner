//
//  InMemoryTaskRepositoryXCTests.swift
//  SmartPlannerTests
//

import XCTest
@testable import SmartPlanner

final class InMemoryTaskRepositoryXCTests: XCTestCase {

    private var suiteName = ""
    private var defaults: UserDefaults?

    override func setUpWithError() throws {
        try super.setUpWithError()
        suiteName = "SmartPlannerTests.InMemoryTaskRepository.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        try XCTSkipIf(defaults == nil, "Could not create isolated UserDefaults suite")
        defaults?.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        defaults?.removePersistentDomain(forName: suiteName)
        defaults = nil
        try super.tearDownWithError()
    }

    func testSaveAddsTask() throws {
        let repository = try makeRepository()
        let task = makeTask(title: "first")

        repository.save(task)

        XCTAssertEqual(repository.fetchAll().map(\.id), [task.id])
    }

    func testFetchAllReturnsSavedTasks() throws {
        let repository = try makeRepository()
        let first = makeTask(title: "first")
        let second = makeTask(title: "second")

        repository.save(first)
        repository.save(second)

        XCTAssertEqual(repository.fetchAll().map(\.title), ["first", "second"])
    }

    func testUpdateReplacesExistingTask() throws {
        let repository = try makeRepository()
        let task = makeTask(title: "task")
        repository.save(task)

        var updated = task
        updated.isCompleted = true
        repository.update(updated)

        XCTAssertEqual(repository.fetchAll().first?.id, task.id)
        XCTAssertEqual(repository.fetchAll().first?.isCompleted, true)
    }

    func testDeleteRemovesTask() throws {
        let repository = try makeRepository()
        let task = makeTask(title: "task")
        repository.save(task)

        repository.delete(id: task.id)

        XCTAssertTrue(repository.fetchAll().isEmpty)
    }

    func testTasksPersistBetweenRepositoryInstances() throws {
        let firstRepository = try makeRepository()
        let task = makeTask(title: "persisted")

        firstRepository.save(task)
        let secondRepository = try makeRepository()

        XCTAssertEqual(secondRepository.fetchAll().map(\.id), [task.id])
    }

    private func makeRepository() throws -> InMemoryTaskRepository {
        let defaults = try XCTUnwrap(defaults)
        return InMemoryTaskRepository(defaults: defaults)
    }

    private func makeTask(title: String) -> Task {
        Task(
            title: title,
            priority: .medium,
            isFlagged: false,
            createdAt: Date(timeIntervalSince1970: 1_750_000_000)
        )
    }
}
