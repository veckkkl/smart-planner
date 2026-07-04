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

    private enum Constants {
        static let storageKey = "SmartPlanner.tasks.v1"
    }

    private let queue = DispatchQueue(label: "InMemoryTaskRepository.queue")
    private let defaults: UserDefaults
    private var storage: [Task] = []
    private var observers: [ObjectIdentifier: (AnyObject, ([Task]) -> Void)] = [:]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.storage = Self.load(from: defaults)
    }

    func save(_ task: Task) {
        queue.sync {
            storage.append(task)
            persist()
        }
        notify()
    }

    func update(_ task: Task) {
        queue.sync {
            guard let index = storage.firstIndex(where: { $0.id == task.id }) else { return }
            storage[index] = task
            persist()
        }
        notify()
    }

    func delete(id: Task.ID) {
        queue.sync {
            storage.removeAll { $0.id == id }
            persist()
        }
        notify()
    }

    func fetchAll() -> [Task] {
        queue.sync { storage }
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(storage) else { return }
        defaults.set(data, forKey: Constants.storageKey)
    }

    private static func load(from defaults: UserDefaults) -> [Task] {
        guard
            let data = defaults.data(forKey: Constants.storageKey),
            let tasks = try? JSONDecoder().decode([Task].self, from: data)
        else { return [] }
        return tasks
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
