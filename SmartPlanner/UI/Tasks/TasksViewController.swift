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

    private enum Layout {
        static let sectionInset: CGFloat = 20
        static let headerVerticalPadding: CGFloat = 8
    }

    private let viewModel: TasksViewModel
    private let compactFilter = CompactFilterControl()
    private let emptyView = EmptyTasksView()
    private let tableView: UITableView = {
        let table = UITableView(frame: .zero, style: .insetGrouped)
        table.translatesAutoresizingMaskIntoConstraints = false
        table.backgroundColor = .systemGroupedBackground
        table.rowHeight = UITableView.automaticDimension
        table.estimatedRowHeight = 64
        table.sectionHeaderTopPadding = 0
        return table
    }()

    private lazy var dataSource: UITableViewDiffableDataSource<TaskListSection, Task.ID> = makeDataSource()
    private var taskIndex: [Task.ID: Task] = [:]
    private var currentSections: [TaskSectionResult] = []

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
        navigationItem.largeTitleDisplayMode = .automatic

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
        addButton.accessibilityIdentifier = "tasks.addButton"
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
        installCompactFilterAsTableHeader()
        view.addSubview(tableView)
        view.addSubview(emptyView)

        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyView.isHidden = true
        emptyView.onCreateTapped = { [weak self] in self?.presentCreateTask() }

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)
        tableView.register(
            TaskSectionHeaderView.self,
            forHeaderFooterViewReuseIdentifier: TaskSectionHeaderView.reuseIdentifier
        )

        compactFilter.onSelectionChange = { [weak self] in self?.viewModel.updateFilter($0) }

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func installCompactFilterAsTableHeader() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        compactFilter.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(compactFilter)
        NSLayoutConstraint.activate([
            compactFilter.topAnchor.constraint(equalTo: container.topAnchor, constant: Layout.headerVerticalPadding),
            compactFilter.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -Layout.headerVerticalPadding),
            compactFilter.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: Layout.sectionInset),
            compactFilter.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -Layout.sectionInset)
        ])
        tableView.tableHeaderView = container
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderIfNeeded()
    }

    private func sizeTableHeaderIfNeeded() {
        guard let header = tableView.tableHeaderView else { return }
        let targetSize = CGSize(width: tableView.bounds.width, height: 0)
        let size = header.systemLayoutSizeFitting(
            targetSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        )
        if abs(header.frame.height - size.height) > 0.5 {
            header.frame.size.height = size.height
            tableView.tableHeaderView = header
        }
    }

    private func bindViewModel() {
        viewModel.onTasksChanged = { [weak self] sections in
            self?.applySnapshot(sections: sections)
        }
    }

    private func makeDataSource() -> UITableViewDiffableDataSource<TaskListSection, Task.ID> {
        let source = UITableViewDiffableDataSource<TaskListSection, Task.ID>(tableView: tableView) { [weak self] table, indexPath, id in
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
        return source
    }

    private func applySnapshot(sections: [TaskSectionResult]) {
        currentSections = sections
        let allTasks = sections.flatMap(\.tasks)
        taskIndex = Dictionary(uniqueKeysWithValues: allTasks.map { ($0.id, $0) })

        var snapshot = NSDiffableDataSourceSnapshot<TaskListSection, Task.ID>()
        for result in sections {
            snapshot.appendSections([result.section])
            let isCollapsed = result.section != .flat && viewModel.isCollapsed(result.section)
            if !isCollapsed {
                snapshot.appendItems(result.tasks.map(\.id), toSection: result.section)
            }
        }
        snapshot.reconfigureItems(snapshot.itemIdentifiers)

        dataSource.apply(snapshot, animatingDifferences: view.window != nil) { [weak self] in
            self?.refreshVisibleHeaders()
        }

        let hasAny = viewModel.hasAnyTasks
        emptyView.isHidden = hasAny
        tableView.isHidden = !hasAny
    }

    private func refreshVisibleHeaders() {
        for index in currentSections.indices {
            let result = currentSections[index]
            guard result.section != .flat,
                  let header = tableView.headerView(forSection: index) as? TaskSectionHeaderView
            else { continue }
            header.configure(
                title: result.section.title,
                count: result.tasks.count,
                isCollapsed: viewModel.isCollapsed(result.section)
            )
        }
    }

    private func presentCreateTask() {
        let createVC = CreateTaskViewController()
        createVC.delegate = self
        navigationController?.pushViewController(createVC, animated: true)
    }
}

extension TasksViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let result = currentSections[safe: section], result.section != .flat else { return nil }
        guard let header = tableView.dequeueReusableHeaderFooterView(
            withIdentifier: TaskSectionHeaderView.reuseIdentifier
        ) as? TaskSectionHeaderView else { return nil }
        let sectionID = result.section
        header.configure(
            title: sectionID.title,
            count: result.tasks.count,
            isCollapsed: viewModel.isCollapsed(sectionID)
        )
        header.onToggle = { [weak self] in
            self?.viewModel.toggleSectionCollapse(sectionID)
        }
        return header
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let result = currentSections[safe: section], result.section != .flat else { return .leastNormalMagnitude }
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
        44
    }

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
        // CreateTaskUseCase persists via repository; observer refreshes list.
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
