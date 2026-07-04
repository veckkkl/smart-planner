//
//  TaskValidator.swift
//  SmartPlanner
//

import Foundation

protocol TaskValidating {
    func isValidTitle(_ title: String) -> Bool
    func sanitize(_ text: String?) -> String?
}

struct TaskValidator: TaskValidating {

    enum Constants {
        static let titleMaxLength = 80
        static let titleMinLength = 1
    }

    func isValidTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= Constants.titleMinLength
            && trimmed.count <= Constants.titleMaxLength
    }

    func sanitize(_ text: String?) -> String? {
        guard let text else { return nil }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
