//
//  NewsViewModel.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import Foundation

final class NewsViewModel {

    enum State {
        case idle
        case loading
        case loaded([NewsArticle])
        case empty
        case error(String)
    }

    var onStateChange: ((State) -> Void)?

    private(set) var state: State = .idle {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.onStateChange?(self.state)
            }
        }
    }

    private let repository: NewsRepositoryProtocol
    private var refreshTimer: Timer?
    private var hasStartedRefreshTimer = false
    private var isLoading = false

    private let refreshInterval: TimeInterval = 120

    init(repository: NewsRepositoryProtocol = NewsRepository()) {
        self.repository = repository
    }

    deinit {
        stopAutoRefresh()
    }

    func viewDidLoad() {
        if let cached = repository.getCachedTopStories() {
            let sortedCached = cached.articles.sorted(by: { $0.publishedAt > $1.publishedAt })
            state = sortedCached.isEmpty ? .empty : .loaded(sortedCached)
            startAutoRefreshIfNeeded()
            loadNewsFromNetwork(showLoader: false, preserveShownContentOnFailure: true)
        } else {
            state = .loading
            loadNewsFromNetwork(showLoader: true, preserveShownContentOnFailure: false)
        }
        repository.sendAnalyticsEvent()
    }

    func retry() {
        let hasContent = hasVisibleContent
        loadNewsFromNetwork(
            showLoader: hasContent == false,
            preserveShownContentOnFailure: hasContent
        )
    }

    func refreshSilently() {
        loadNewsFromNetwork(showLoader: false, preserveShownContentOnFailure: true)
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        hasStartedRefreshTimer = false
    }

    private func startAutoRefreshIfNeeded() {
        guard hasStartedRefreshTimer == false else { return }

        hasStartedRefreshTimer = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.refreshTimer = Timer.scheduledTimer(withTimeInterval: self.refreshInterval, repeats: true) { [weak self] _ in
                self?.refreshSilently()
            }
        }
    }

    private var hasVisibleContent: Bool {
        switch state {
        case .loaded, .empty:
            return true
        case .idle, .loading, .error:
            return false
        }
    }

    private func loadNewsFromNetwork(
        showLoader: Bool,
        preserveShownContentOnFailure: Bool
    ) {
        guard isLoading == false else { return }
        isLoading = true

        if showLoader {
            state = .loading
        }

        repository.refreshTopStories { [weak self] result in
            guard let self else { return }
            self.isLoading = false

            switch result {
            case .success(let articles):
                let sorted = articles.sorted(by: { $0.publishedAt > $1.publishedAt })

                if sorted.isEmpty {
                    self.state = .empty
                } else {
                    self.state = .loaded(sorted)
                }

                self.startAutoRefreshIfNeeded()

            case .failure(let error):
                if preserveShownContentOnFailure || self.hasVisibleContent {
                    return
                }
                self.state = .error(self.makeErrorMessage(from: .failure(error)))
            }
        }
    }

    private func makeErrorMessage(from result: Result<[NewsArticle], Error>) -> String {
        guard case .failure(let error) = result else {
            return "Не удалось загрузить новости."
        }

        if let apiError = error as? APIClientError {
            return apiError.localizedDescription
        }

        if let repositoryError = error as? NewsRepositoryError {
            switch repositoryError {
            case .invalidAPIStatus(let status):
                return "NYTimes вернул статус \(status)."
            }
        }

        return "Не удалось загрузить новости. Проверьте интернет и попробуйте снова."
    }
}
