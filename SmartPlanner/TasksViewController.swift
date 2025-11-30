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

    private let tableView = UITableView()
    private var tasks: [Task] = []

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
        navigationItem.rightBarButtonItem = addButton
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self

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
            backgroundView.translatesAutoresizingMaskIntoConstraints = false

            let label = UILabel()
            label.text = "Задач нет"
            label.textColor = .secondaryLabel
            label.translatesAutoresizingMaskIntoConstraints = false

            backgroundView.addSubview(label)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: backgroundView.topAnchor, constant: 16),
                label.leadingAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: 16),
                label.trailingAnchor.constraint(lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -16)
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
}

extension TasksViewController: UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        tasks.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let identifier = "TaskCell"

        let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
            ?? UITableViewCell(style: .default, reuseIdentifier: identifier)

        let task = tasks[indexPath.row]
        cell.textLabel?.text = task.title

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
