//
//  CreateTaskTests.swift
//  SmartPlannerTests
//

import Testing
import Foundation
@testable import SmartPlanner

struct TaskValidatorTests {

    @Test func acceptsTrimmedNonEmptyTitle() {
        let sut = TaskValidator()
        #expect(sut.isValidTitle("Buy milk"))
    }

    @Test func rejectsEmptyTitle() {
        let sut = TaskValidator()
        #expect(sut.isValidTitle("") == false)
    }

    @Test func rejectsWhitespaceOnlyTitle() {
        let sut = TaskValidator()
        #expect(sut.isValidTitle("    ") == false)
    }

    @Test func rejectsOverLongTitle() {
        let sut = TaskValidator()
        let overLong = String(repeating: "a", count: TaskValidator.Constants.titleMaxLength + 1)
        #expect(sut.isValidTitle(overLong) == false)
    }

    @Test func sanitizeReturnsNilForBlank() {
        let sut = TaskValidator()
        #expect(sut.sanitize("   ") == nil)
        #expect(sut.sanitize(nil) == nil)
    }

    @Test func sanitizeTrimsValue() {
        let sut = TaskValidator()
        #expect(sut.sanitize("  hello  ") == "hello")
    }
}

private final class TaskRepositorySpy: TaskRepositoryProtocol {
    private(set) var saved: [Task] = []
    func save(_ task: Task) { saved.append(task) }
}

struct CreateTaskUseCaseTests {

    @Test func createsTaskOnValidInput() {
        let spy = TaskRepositorySpy()
        let sut = CreateTaskUseCase(validator: TaskValidator(), repository: spy)
        let input = CreateTaskInput(
            title: " Hello ",
            details: "  details  ",
            priority: .high,
            isFlagged: true,
            deadline: nil
        )

        let result = sut.execute(input)

        switch result {
        case .success(let task):
            #expect(task.title == "Hello")
            #expect(task.details == "details")
            #expect(task.priority == .high)
            #expect(task.isFlagged == true)
            #expect(spy.saved.count == 1)
        case .failure:
            Issue.record("Expected success")
        }
    }

    @Test func failsOnInvalidTitle() {
        let spy = TaskRepositorySpy()
        let sut = CreateTaskUseCase(validator: TaskValidator(), repository: spy)
        let input = CreateTaskInput(
            title: "   ",
            details: nil,
            priority: .low,
            isFlagged: false,
            deadline: nil
        )

        let result = sut.execute(input)

        switch result {
        case .success:
            Issue.record("Expected failure")
        case .failure(let error):
            #expect(error == .invalidTitle)
        }
        #expect(spy.saved.isEmpty)
    }
}
