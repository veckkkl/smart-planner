//
//  CreateTaskUseCase.swift
//  SmartPlanner
//

import Foundation

struct CreateTaskInput {
    let title: String
    let details: String?
    let priority: TaskPriority
    let isFlagged: Bool
    let deadline: Date?
}

enum CreateTaskError: Error, Equatable {
    case invalidTitle
}

protocol CreateTaskUseCaseProtocol {
    func execute(_ input: CreateTaskInput) -> Result<Task, CreateTaskError>
}

struct CreateTaskUseCase: CreateTaskUseCaseProtocol {

    private let validator: TaskValidating
    private let repository: TaskRepositoryProtocol

    init(
        validator: TaskValidating = TaskValidator(),
        repository: TaskRepositoryProtocol = InMemoryTaskRepository.shared
    ) {
        self.validator = validator
        self.repository = repository
    }

    func execute(_ input: CreateTaskInput) -> Result<Task, CreateTaskError> {
        guard validator.isValidTitle(input.title) else {
            return .failure(.invalidTitle)
        }

        let task = Task(
            title: input.title.trimmingCharacters(in: .whitespacesAndNewlines),
            details: validator.sanitize(input.details),
            priority: input.priority,
            isFlagged: input.isFlagged,
            deadline: input.deadline
        )

        repository.save(task)
        return .success(task)
    }
}
