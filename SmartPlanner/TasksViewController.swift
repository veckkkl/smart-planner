//
//  TasksViewController.swift
//  SmartPlanner
//
//  Created by valentina balde on 11/30/25.
//

import UIKit

protocol CreateTaskViewControllerDelegate: AnyObject {
    func createTaskViewController(
        _ viewController: CreateTaskViewController,
        didCreateTask task: Task
    )
}

final class TasksViewController: UIViewController {

    private enum SortOption {
        case none
        case dateNewest
        case dateOldest
        case priorityHighFirst
        case priorityLowFirst
    }

    private let tableView = UITableView()
    private var tasks: [Task] = []
    private var sortOption: SortOption = .none

    private var displayedTasks: [Task] {
        var result = tasks

        switch sortOption {
        case .none:
            return result

        case .dateNewest:
            result.sort { lhs, rhs in
                lhs.createdAt > rhs.createdAt
            }
            return result

        case .dateOldest:
            result.sort { lhs, rhs in
                lhs.createdAt < rhs.createdAt
            }
            return result

        case .priorityHighFirst:
            result.sort { lhs, rhs in
                lhs.priority.rawValue > rhs.priority.rawValue
            }
            return result

        case .priorityLowFirst:
            result.sort { lhs, rhs in
                lhs.priority.rawValue < rhs.priority.rawValue
            }
            return result
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Задачи"

        setupTableView()
        setupNavigationBar()
        updateEmptyState()
    }

    private func setupNavigationBar() {
        let addButton = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTaskTapped)
        )

        let sortMenu = makeSortMenu()
        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            primaryAction: nil,
            menu: sortMenu
        )
        navigationItem.rightBarButtonItems = [addButton, sortButton]
    }

    private func makeSortMenu() -> UIMenu {
        let newest = UIAction(
            title: "Сначала новые"
        ) { [weak self] _ in
            self?.sortOption = .dateNewest
            self?.tableView.reloadData()
        }

        let oldest = UIAction(
            title: "Сначала старые"
        ) { [weak self] _ in
            self?.sortOption = .dateOldest
            self?.tableView.reloadData()
        }

        let highFirst = UIAction(
            title: "Сначала сложные"
        ) { [weak self] _ in
            self?.sortOption = .priorityHighFirst
            self?.tableView.reloadData()
        }

        let lowFirst = UIAction(
            title: "Сначала лёгкие"
        ) { [weak self] _ in
            self?.sortOption = .priorityLowFirst
            self?.tableView.reloadData()
        }

        let menu = UIMenu(
            children: [newest, oldest, highFirst, lowFirst]
        )
        return menu
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func updateEmptyState() {
        if tasks.isEmpty {
            let backgroundView = UIView(frame: tableView.bounds)

            let label = UILabel()
            label.text = "Задач нет"
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false

            backgroundView.addSubview(label)

            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: backgroundView.safeAreaLayoutGuide.centerYAnchor)
            ])

            tableView.backgroundView = backgroundView
        } else {
            tableView.backgroundView = nil
        }
    }

    @objc
    private func addTaskTapped() {
        let createVC = CreateTaskViewController()
        createVC.delegate = self
        navigationController?.pushViewController(createVC, animated: true)
    }

    private func toggleCompleted(for task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        tableView.reloadData()
    }
}

extension TasksViewController: UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        displayedTasks.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TaskCell.reuseIdentifier,
            for: indexPath
        ) as? TaskCell else {
            return UITableViewCell()
        }

        let task = displayedTasks[indexPath.row]
        cell.configure(with: task)
        cell.onToggleCompleted = { [weak self] in
            self?.toggleCompleted(for: task)
            self?.updateEmptyState()
        }

        return cell
    }
}
extension TasksViewController: UITableViewDelegate { }

extension TasksViewController: CreateTaskViewControllerDelegate {
    func createTaskViewController(
        _ viewController: CreateTaskViewController,
        didCreateTask task: Task
    ) {
        tasks.append(task)
        tableView.reloadData()
        updateEmptyState()
    }
}
