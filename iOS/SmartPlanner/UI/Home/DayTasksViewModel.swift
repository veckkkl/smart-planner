//
//  DayTasksViewModel.swift
//  SmartPlanner
//

import Foundation

struct DayTasksState: Equatable {
    let tasks: [Task]

    var isEmpty: Bool {
        tasks.isEmpty
    }
}

final class DayTasksViewModel {

    var onStateChanged: ((DayTasksState) -> Void)?

    let day: Date

    private(set) var state: DayTasksState {
        didSet { onStateChanged?(state) }
    }

    private let repository: TaskRepositoryProtocol
    private let service: DashboardStatisticsServicing

    init(
        day: Date,
        initialTasks: [Task] = [],
        repository: TaskRepositoryProtocol = InMemoryTaskRepository.shared,
        service: DashboardStatisticsServicing = DashboardStatisticsService()
    ) {
        self.day = day
        self.repository = repository
        self.service = service
        self.state = DayTasksState(tasks: initialTasks)
    }

    func start() {
        repository.addObserver(self) { [weak self] tasks in
            self?.process(tasks)
        }
    }

    func stop() {
        repository.removeObserver(self)
    }

    func task(at index: Int) -> Task? {
        guard state.tasks.indices.contains(index) else { return nil }
        return state.tasks[index]
    }

    func toggleCompletion(taskID: Task.ID) {
        guard var task = state.tasks.first(where: { $0.id == taskID }) else { return }
        task.isCompleted.toggle()
        repository.update(task)
        refresh()
    }

    private func refresh() {
        process(repository.fetchAll())
    }

    private func process(_ tasks: [Task]) {
        state = DayTasksState(tasks: service.tasks(on: day, from: tasks))
    }
}
