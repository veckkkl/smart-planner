//
//  TaskRepository.swift
//  SmartPlanner
//

import Foundation

protocol TaskRepositoryProtocol {
    func save(_ task: Task)
}

final class InMemoryTaskRepository: TaskRepositoryProtocol {

    static let shared = InMemoryTaskRepository()

    private let queue = DispatchQueue(label: "InMemoryTaskRepository.queue")
    private var storage: [Task] = []

    func save(_ task: Task) {
        queue.sync { storage.append(task) }
    }
}
