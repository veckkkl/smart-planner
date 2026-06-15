//
//  DayTasksViewController.swift
//  SmartPlanner
//

import UIKit

final class DayTasksViewController: UIViewController {

    private let day: Date
    private let tasks: [Task]
    private let repository: TaskRepositoryProtocol
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = EmptyTasksView()

    init(day: Date, tasks: [Task], repository: TaskRepositoryProtocol = InMemoryTaskRepository.shared) {
        self.day = day
        self.tasks = tasks
        self.repository = repository
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = Self.formatter.string(from: day)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64

        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = !tasks.isEmpty
        tableView.isHidden = tasks.isEmpty

        view.addSubview(tableView)
        view.addSubview(emptyView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale.autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("ddMMMM")
        return formatter
    }()
}

extension DayTasksViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier, for: indexPath) as? TaskCell else {
            return UITableViewCell()
        }
        let task = tasks[indexPath.row]
        cell.configure(with: task)
        cell.onToggleCompleted = { [weak self] in
            guard let self else { return }
            var updated = task
            updated.isCompleted.toggle()
            self.repository.update(updated)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        return cell
    }
}
