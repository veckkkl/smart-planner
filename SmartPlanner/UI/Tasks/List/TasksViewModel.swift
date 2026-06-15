//
//  TasksViewModel.swift
//  SmartPlanner
//

import Foundation

final class TasksViewModel {

    var onTasksChanged: (([Task]) -> Void)?

    private(set) var filter: TaskFilter = .all
    private(set) var sortOption: TaskSortOption = .dateNewest

    private let repository: TaskRepositoryProtocol
    private let processor: TaskListProcessing
    private var allTasks: [Task] = []

    init(
        repository: TaskRepositoryProtocol = InMemoryTaskRepository.shared,
        processor: TaskListProcessing = TaskListProcessor()
    ) {
        self.repository = repository
        self.processor = processor
    }

    func start() {
        repository.addObserver(self) { [weak self] tasks in
            self?.handleRepositoryUpdate(tasks)
        }
    }

    func stop() {
        repository.removeObserver(self)
    }

    var displayedTasks: [Task] {
        processor.process(allTasks, filter: filter, sort: sortOption)
    }

    var totalCount: Int { allTasks.count }

    func updateFilter(_ value: TaskFilter) {
        filter = value
        onTasksChanged?(displayedTasks)
    }

    func updateSort(_ value: TaskSortOption) {
        sortOption = value
        onTasksChanged?(displayedTasks)
    }

    func add(_ task: Task) {
        repository.save(task)
    }

    func toggleCompletion(taskID: Task.ID) {
        guard var task = allTasks.first(where: { $0.id == taskID }) else { return }
        task.isCompleted.toggle()
        repository.update(task)
    }

    func delete(taskID: Task.ID) {
        repository.delete(id: taskID)
    }

    private func handleRepositoryUpdate(_ tasks: [Task]) {
        allTasks = tasks
        onTasksChanged?(displayedTasks)
    }
}
