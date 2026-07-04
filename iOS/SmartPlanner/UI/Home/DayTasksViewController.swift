//
//  DayTasksViewController.swift
//  SmartPlanner
//

import UIKit

final class DayTasksViewController: UIViewController {

    private let viewModel: DayTasksViewModel
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let emptyView = EmptyTasksView()

    init(day: Date, tasks: [Task]) {
        self.viewModel = DayTasksViewModel(day: day, initialTasks: tasks)
        super.init(nibName: nil, bundle: nil)
    }

    init(viewModel: DayTasksViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = Self.formatter.string(from: viewModel.day)

        setupLayout()
        bindViewModel()
        render(viewModel.state)
        viewModel.start()
    }

    deinit { viewModel.stop() }

    private func setupLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)
        tableView.backgroundColor = .systemGroupedBackground
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 64

        emptyView.translatesAutoresizingMaskIntoConstraints = false

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

    private func bindViewModel() {
        viewModel.onStateChanged = { [weak self] state in
            self?.render(state)
        }
    }

    private func render(_ state: DayTasksState) {
        emptyView.isHidden = !state.isEmpty
        tableView.isHidden = state.isEmpty
        tableView.reloadData()
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
        viewModel.state.tasks.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: TaskCell.reuseIdentifier, for: indexPath) as? TaskCell,
            let task = viewModel.task(at: indexPath.row)
        else {
            return UITableViewCell()
        }
        cell.configure(with: task)
        cell.onToggleCompleted = { [weak self] in
            self?.viewModel.toggleCompletion(taskID: task.id)
        }
        return cell
    }
}
