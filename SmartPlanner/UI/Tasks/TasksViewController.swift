//
//  TasksViewController.swift
//  SmartPlanner
//

import UIKit

protocol CreateTaskViewControllerDelegate: AnyObject {
    func createTaskViewController(
        _ viewController: CreateTaskViewController,
        didCreateTask task: Task
    )
}

final class TasksViewController: UIViewController {

    private enum Strings {
        static let screenTitle = "Задачи"
        static let delete = "Удалить"
        static let complete = "Готово"
        static let uncomplete = "Снять"
    }

    private enum Section { case main }

    private let viewModel: TasksViewModel
    private let filterControl = TaskFilterControl()
    private let toolbarView = TaskToolbarView()
    private let emptyView = EmptyTasksView()
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .systemGroupedBackground
        table.separatorInset = UIEdgeInsets(
            top: 0,
            left: DesignTokens.Spacing.xxl,
            bottom: 0,
            right: 0
        )
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 64
        return table
    }()

    private lazy var dataSource: UITableViewDiffableDataSource<Section, Task.ID> = makeDataSource()
    private var taskIndex: [Task.ID: Task] = [:]

    init(viewModel: TasksViewModel = TasksViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = Strings.screenTitle
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always

        setupNavigationBar()
        setupLayout()
        bindViewModel()
        viewModel.start()
    }

    deinit { viewModel.stop() }

    private func setupNavigationBar() {
        let addAction = UIAction(image: UIImage(systemName: "plus")) { [weak self] _ in
            self?.presentCreateTask()
        }
        let addButton = UIBarButtonItem(primaryAction: addAction)

        let sortButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.up.arrow.down"),
            menu: makeSortMenu()
        )

        navigationItem.rightBarButtonItems = [addButton, sortButton]
    }

    private func makeSortMenu() -> UIMenu {
        let actions = TaskSortOption.allCases.map { option in
            UIAction(
                title: option.title,
                image: UIImage(systemName: option.symbolName),
                state: option == viewModel.sortOption ? .on : .off
            ) { [weak self] _ in
                self?.viewModel.updateSort(option)
                self?.setupNavigationBar()
            }
        }
        return UIMenu(title: "Сортировка", children: actions)
    }

    private func setupLayout() {
        view.addSubview(toolbarView)
        view.addSubview(filterControl)
        view.addSubview(tableView)
        view.addSubview(emptyView)

        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        emptyView.onCreateTapped = { [weak self] in self?.presentCreateTask() }

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)

        filterControl.onSelectionChange = { [weak self] in self?.viewModel.updateFilter($0) }

        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            toolbarView.topAnchor.constraint(equalTo: safe.topAnchor),
            toolbarView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            toolbarView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            filterControl.topAnchor.constraint(equalTo: toolbarView.bottomAnchor),
            filterControl.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            filterControl.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: filterControl.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.topAnchor.constraint(equalTo: tableView.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onTasksChanged = { [weak self] tasks in
            self?.applySnapshot(with: tasks)
        }
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<Section, Task.ID> {
        UITableViewDiffableDataSource(tableView: tableView) { [weak self] table, indexPath, id in
            guard
                let self,
                let cell = table.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier, for: indexPath) as? TaskCell,
                let task = self.taskIndex[id]
            else {
                return UITableViewCell()
            }
            cell.configure(with: task)
            cell.onToggleCompleted = { [weak self] in
                self?.viewModel.toggleCompletion(taskID: id)
            }
            return cell
        }
    }

    private func applySnapshot(with tasks: [Task]) {
        taskIndex = Dictionary(uniqueKeysWithValues: tasks.map { ($0.id, $0) })
        var snapshot = NSDiffableDataSourceSnapshot<Section, Task.ID>()
        snapshot.appendSections([.main])
        snapshot.appendItems(tasks.map(\.id), toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: view.window != nil)
        toolbarView.setCount(viewModel.totalCount)
        emptyView.isHidden = viewModel.totalCount > 0
        tableView.isHidden = viewModel.totalCount == 0
    }

    private func presentCreateTask() {
        let createVC = CreateTaskViewController()
        createVC.delegate = self
        navigationController?.pushViewController(createVC, animated: true)
    }
}

extension TasksViewController: UITableViewDelegate {

    func tableView(
        _ tableView: UITableView,
        leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let task = task(at: indexPath) else { return nil }
        let title = task.isCompleted ? Strings.uncomplete : Strings.complete
        let action = UIContextualAction(style: .normal, title: title) { [weak self] _, _, done in
            self?.viewModel.toggleCompletion(taskID: task.id)
            done(true)
        }
        action.backgroundColor = .systemGreen
        action.image = UIImage(systemName: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
        return UISwipeActionsConfiguration(actions: [action])
    }

    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard let task = task(at: indexPath) else { return nil }
        let delete = UIContextualAction(style: .destructive, title: Strings.delete) { [weak self] _, _, done in
            self?.viewModel.delete(taskID: task.id)
            done(true)
        }
        delete.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(
        _ tableView: UITableView,
        contextMenuConfigurationForRowAt indexPath: IndexPath,
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard let task = task(at: indexPath) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            let toggleTitle = task.isCompleted ? Strings.uncomplete : Strings.complete
            let toggle = UIAction(
                title: toggleTitle,
                image: UIImage(systemName: task.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
            ) { _ in
                self?.viewModel.toggleCompletion(taskID: task.id)
            }
            let delete = UIAction(
                title: Strings.delete,
                image: UIImage(systemName: "trash"),
                attributes: .destructive
            ) { _ in
                self?.viewModel.delete(taskID: task.id)
            }
            return UIMenu(children: [toggle, delete])
        }
    }

    private func task(at indexPath: IndexPath) -> Task? {
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return nil }
        return taskIndex[id]
    }
}

extension TasksViewController: CreateTaskViewControllerDelegate {
    func createTaskViewController(
        _ viewController: CreateTaskViewController,
        didCreateTask task: Task
    ) {
        // CreateTaskUseCase already persisted to repository — repository observer will refresh.
        // We avoid double-add here.
    }
}
