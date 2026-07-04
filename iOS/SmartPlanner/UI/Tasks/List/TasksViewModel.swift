//
//  TasksViewModel.swift
//  SmartPlanner
//

import Foundation

final class TasksViewModel {

    var onTasksChanged: (([TaskSectionResult]) -> Void)?

    private(set) var filter: TaskFilter = .all
    private(set) var sortOption: TaskSortOption = .dateNewest
    private(set) var collapsedSections: Set<TaskListSection> = []

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

    var sections: [TaskSectionResult] {
        processor.process(allTasks, filter: filter, sort: sortOption)
    }

    var totalCount: Int { allTasks.count }

    var hasAnyTasks: Bool { !allTasks.isEmpty }

    func updateFilter(_ value: TaskFilter) {
        filter = value
        onTasksChanged?(sections)
    }

    func updateSort(_ value: TaskSortOption) {
        sortOption = value
        onTasksChanged?(sections)
    }

    func toggleSectionCollapse(_ section: TaskListSection) {
        if collapsedSections.contains(section) {
            collapsedSections.remove(section)
        } else {
            collapsedSections.insert(section)
        }
        onTasksChanged?(sections)
    }

    func isCollapsed(_ section: TaskListSection) -> Bool {
        collapsedSections.contains(section)
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
        onTasksChanged?(sections)
    }
}
