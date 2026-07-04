//
//  CreateTaskViewModel.swift
//  SmartPlanner
//

import Foundation

final class CreateTaskViewModel {

    var onValidityChanged: ((Bool) -> Void)?
    var onTaskCreated: ((Task) -> Void)?
    var onValidationError: (() -> Void)?

    private(set) var title: String = "" {
        didSet { onValidityChanged?(isValid) }
    }
    private(set) var details: String = ""
    private(set) var priority: TaskPriority = .medium
    private(set) var isFlagged: Bool = false
    private(set) var isDeadlineEnabled: Bool = false
    private(set) var deadline: Date = Date()

    let titleCharacterLimit = TaskValidator.Constants.titleMaxLength

    var isValid: Bool { validator.isValidTitle(title) }

    private let useCase: CreateTaskUseCaseProtocol
    private let validator: TaskValidating

    init(
        useCase: CreateTaskUseCaseProtocol = CreateTaskUseCase(),
        validator: TaskValidating = TaskValidator()
    ) {
        self.useCase = useCase
        self.validator = validator
    }

    func updateTitle(_ value: String) { title = value }
    func updateDetails(_ value: String) { details = value }
    func updatePriority(_ value: TaskPriority) { priority = value }
    func updateFlagged(_ value: Bool) { isFlagged = value }
    func updateDeadlineEnabled(_ value: Bool) { isDeadlineEnabled = value }
    func updateDeadline(_ value: Date) { deadline = value }

    func save() {
        let input = CreateTaskInput(
            title: title,
            details: details,
            priority: priority,
            isFlagged: isFlagged,
            deadline: isDeadlineEnabled ? deadline : nil
        )
        switch useCase.execute(input) {
        case .success(let task):
            onTaskCreated?(task)
        case .failure:
            onValidationError?()
        }
    }
}
