//
//  TaskRepository.swift
//  SmartPlanner
//

import Foundation

protocol TaskRepositoryProtocol: AnyObject {
    func save(_ task: Task)
    func update(_ task: Task)
    func delete(id: Task.ID)
    func fetchAll() -> [Task]
    func addObserver(_ observer: AnyObject, onChange: @escaping ([Task]) -> Void)
    func removeObserver(_ observer: AnyObject)
}

final class InMemoryTaskRepository: TaskRepositoryProtocol {

    static let shared = InMemoryTaskRepository()

    private let queue = DispatchQueue(label: "InMemoryTaskRepository.queue")
    private var storage: [Task] = []
    private var observers: [ObjectIdentifier: (AnyObject, ([Task]) -> Void)] = [:]

    func save(_ task: Task) {
        queue.sync { storage.append(task) }
        notify()
    }

    func update(_ task: Task) {
        queue.sync {
            guard let index = storage.firstIndex(where: { $0.id == task.id }) else { return }
            storage[index] = task
        }
        notify()
    }

    func delete(id: Task.ID) {
        queue.sync { storage.removeAll { $0.id == id } }
        notify()
    }

    func fetchAll() -> [Task] {
        queue.sync { storage }
    }

    func addObserver(_ observer: AnyObject, onChange: @escaping ([Task]) -> Void) {
        let key = ObjectIdentifier(observer)
        observers[key] = (observer, onChange)
        onChange(fetchAll())
    }

    func removeObserver(_ observer: AnyObject) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
    }

    private func notify() {
        let snapshot = fetchAll()
        let active = observers.values.filter { $0.0 !== (nil as AnyObject?) }
        DispatchQueue.main.async {
            active.forEach { $0.1(snapshot) }
        }
    }
}
