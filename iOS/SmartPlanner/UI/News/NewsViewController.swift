//
//  NewsViewController.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import UIKit

final class NewsViewController: UIViewController {

    private let viewModel: NewsViewModel

    private var articles: [NewsArticle] = []

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let stateLabel = UILabel()
    private let retryButton = UIButton(type: .system)

    init(viewModel: NewsViewModel = NewsViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Новости"
        view.backgroundColor = .systemBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .automatic

        setupTableView()
        setupStateViews()
        bindViewModel()

        viewModel.viewDidLoad()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            viewModel.stopAutoRefresh()
        }
    }

    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(NewsCell.self, forCellReuseIdentifier: NewsCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 360
        tableView.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 16, right: 0)
        tableView.keyboardDismissMode = .onDrag
        tableView.isHidden = true

        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupStateViews() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true

        stateLabel.translatesAutoresizingMaskIntoConstraints = false
        stateLabel.textColor = .secondaryLabel
        stateLabel.textAlignment = .center
        stateLabel.numberOfLines = 0
        stateLabel.isHidden = true

        retryButton.translatesAutoresizingMaskIntoConstraints = false
        retryButton.setTitle("Повторить", for: .normal)
        retryButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        retryButton.isHidden = true
        retryButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)

        view.addSubview(loadingIndicator)
        view.addSubview(stateLabel)
        view.addSubview(retryButton)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            stateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12),

            retryButton.topAnchor.constraint(equalTo: stateLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state: state)
        }
    }

    private func render(state: NewsViewModel.State) {
        switch state {
        case .idle:
            tableView.isHidden = true
            loadingIndicator.stopAnimating()
            stateLabel.isHidden = true
            retryButton.isHidden = true

        case .loading:
            if articles.isEmpty {
                tableView.isHidden = true
                loadingIndicator.startAnimating()
            }
            stateLabel.isHidden = true
            retryButton.isHidden = true

        case .loaded(let news):
            articles = news
            tableView.reloadData()
            tableView.isHidden = false
            loadingIndicator.stopAnimating()
            stateLabel.isHidden = true
            retryButton.isHidden = true

        case .empty:
            articles = []
            tableView.reloadData()
            tableView.isHidden = true
            loadingIndicator.stopAnimating()
            stateLabel.text = "Новостей пока нет"
            stateLabel.isHidden = false
            retryButton.isHidden = false

        case .error(let message):
            if articles.isEmpty {
                tableView.isHidden = true
            }
            loadingIndicator.stopAnimating()
            stateLabel.text = message
            stateLabel.isHidden = false
            retryButton.isHidden = false
        }
    }

    @objc
    private func retryTapped() {
        viewModel.retry()
    }
}

extension NewsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        articles.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: NewsCell.reuseIdentifier,
            for: indexPath
        ) as? NewsCell else {
            return UITableViewCell()
        }

        let article = articles[indexPath.row]
        cell.configure(with: article)
        return cell
    }
}
