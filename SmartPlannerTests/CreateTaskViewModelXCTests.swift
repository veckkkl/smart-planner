//
//  CreateTaskViewModelXCTests.swift
//  SmartPlannerTests
//

import XCTest
@testable import SmartPlanner

final class CreateTaskViewModelXCTests: XCTestCase {

    func testInitialState() {
        let sut = CreateTaskViewModel(useCase: CreateTaskUseCaseFake(), validator: TaskValidator())

        XCTAssertEqual(sut.title, "")
        XCTAssertEqual(sut.details, "")
        XCTAssertEqual(sut.priority, .medium)
        XCTAssertFalse(sut.isFlagged)
        XCTAssertFalse(sut.isDeadlineEnabled)
        XCTAssertFalse(sut.isValid)
    }

    func testEmptyTitleIsInvalid() {
        let sut = CreateTaskViewModel(useCase: CreateTaskUseCaseFake(), validator: TaskValidator())
        var validityValues: [Bool] = []
        sut.onValidityChanged = { validityValues.append($0) }

        sut.updateTitle("   ")

        XCTAssertFalse(sut.isValid)
        XCTAssertEqual(validityValues, [false])
    }

    func testNonEmptyTitleIsValid() {
        let sut = CreateTaskViewModel(useCase: CreateTaskUseCaseFake(), validator: TaskValidator())
        var validityValues: [Bool] = []
        sut.onValidityChanged = { validityValues.append($0) }

        sut.updateTitle("Plan week")

        XCTAssertTrue(sut.isValid)
        XCTAssertEqual(validityValues, [true])
    }

    func testPriorityCanBeChanged() {
        let sut = CreateTaskViewModel(useCase: CreateTaskUseCaseFake(), validator: TaskValidator())

        sut.updatePriority(.high)

        XCTAssertEqual(sut.priority, .high)
    }

    func testFlagCanBeEnabledAndDisabled() {
        let sut = CreateTaskViewModel(useCase: CreateTaskUseCaseFake(), validator: TaskValidator())

        sut.updateFlagged(true)
        XCTAssertTrue(sut.isFlagged)

        sut.updateFlagged(false)
        XCTAssertFalse(sut.isFlagged)
    }

    func testDeadlineCanBeEnabledDisabledAndUpdated() {
        let sut = CreateTaskViewModel(useCase: CreateTaskUseCaseFake(), validator: TaskValidator())
        let deadline = Date(timeIntervalSince1970: 1_750_000_000)

        sut.updateDeadlineEnabled(true)
        sut.updateDeadline(deadline)
        XCTAssertTrue(sut.isDeadlineEnabled)
        XCTAssertEqual(sut.deadline, deadline)

        sut.updateDeadlineEnabled(false)
        XCTAssertFalse(sut.isDeadlineEnabled)
    }

    func testSaveCreatesTaskThroughUseCase() throws {
        let task = Task(title: "Plan", priority: .high, isFlagged: true)
        let useCase = CreateTaskUseCaseFake(result: .success(task))
        let sut = CreateTaskViewModel(useCase: useCase, validator: TaskValidator())
        let deadline = Date(timeIntervalSince1970: 1_750_000_000)
        var createdTask: Task?

        sut.onTaskCreated = { createdTask = $0 }
        sut.updateTitle("Plan")
        sut.updateDetails("Details")
        sut.updatePriority(.high)
        sut.updateFlagged(true)
        sut.updateDeadlineEnabled(true)
        sut.updateDeadline(deadline)

        sut.save()

        let input = try XCTUnwrap(useCase.receivedInput)
        XCTAssertEqual(input.title, "Plan")
        XCTAssertEqual(input.details, "Details")
        XCTAssertEqual(input.priority, .high)
        XCTAssertTrue(input.isFlagged)
        XCTAssertEqual(input.deadline, deadline)
        XCTAssertEqual(createdTask?.id, task.id)
    }

    func testValidationFailureDoesNotCreateTask() {
        let useCase = CreateTaskUseCaseFake(result: .failure(.invalidTitle))
        let sut = CreateTaskViewModel(useCase: useCase, validator: TaskValidator())
        var didCreateTask = false
        var didReceiveValidationError = false

        sut.onTaskCreated = { _ in didCreateTask = true }
        sut.onValidationError = { didReceiveValidationError = true }

        sut.save()

        XCTAssertFalse(didCreateTask)
        XCTAssertTrue(didReceiveValidationError)
    }
}

private final class CreateTaskUseCaseFake: CreateTaskUseCaseProtocol {
    private let result: Result<Task, CreateTaskError>
    private(set) var receivedInput: CreateTaskInput?

    init(result: Result<Task, CreateTaskError> = .failure(.invalidTitle)) {
        self.result = result
    }

    func execute(_ input: CreateTaskInput) -> Result<Task, CreateTaskError> {
        receivedInput = input
        return result
    }
}
