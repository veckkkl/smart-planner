//
//  NewsViewModelXCTests.swift
//  SmartPlannerTests
//

import XCTest
@testable import SmartPlanner

final class NewsViewModelXCTests: XCTestCase {

    private var repository: StubNewsRepository!
    private var sut: NewsViewModel!

    override func setUp() {
        super.setUp()
        repository = StubNewsRepository()
        sut = NewsViewModel(repository: repository)
    }

    override func tearDown() {
        sut.stopAutoRefresh()
        sut = nil
        repository = nil
        super.tearDown()
    }

    func test_initialStateIsIdle() {
        if case .idle = sut.state {} else { XCTFail("expected .idle") }
    }

    func test_viewDidLoadTransitionsToLoadedOnSuccess() {
        repository.refreshResult = .success([makeArticle(id: "1", title: "A")])

        let final = waitForFinalState { self.sut.viewDidLoad() }

        guard case .loaded(let articles) = final else {
            return XCTFail("expected .loaded, got \(final)")
        }
        XCTAssertEqual(articles.map(\.id), ["1"])
    }

    func test_viewDidLoadShowsLoadingBeforeResult() {
        repository.refreshResult = .success([])
        var seen: [NewsViewModel.State] = []
        let firstStateExpectation = expectation(description: "first state")

        sut.onStateChange = { state in
            seen.append(state)
            if seen.count == 1 { firstStateExpectation.fulfill() }
        }

        sut.viewDidLoad()
        wait(for: [firstStateExpectation], timeout: 1)

        if case .loading = seen.first {} else { XCTFail("first state should be .loading") }
    }

    func test_viewDidLoadShowsEmptyWhenServerReturnsEmpty() {
        repository.refreshResult = .success([])

        let final = waitForFinalState { self.sut.viewDidLoad() }

        if case .empty = final {} else { XCTFail("expected .empty") }
    }

    func test_viewDidLoadShowsErrorOnFailure() {
        repository.refreshResult = .failure(URLError(.notConnectedToInternet))

        let final = waitForFinalState { self.sut.viewDidLoad() }

        if case .error(let message) = final {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("expected .error, got \(final)")
        }
    }

    func test_viewDidLoadUsesCacheImmediatelyAndKeepsContentOnNetworkFailure() {
        let cached = [makeArticle(id: "cached", title: "Cached")]
        repository.cachedResult = CachedTopStories(articles: cached, savedAt: Date(), isSoftTTLExpired: false)
        repository.refreshResult = .failure(URLError(.timedOut))

        let firstLoaded = expectation(description: "loaded from cache")
        var lastState: NewsViewModel.State = .idle
        sut.onStateChange = { state in
            lastState = state
            if case .loaded = state { firstLoaded.fulfill() }
        }

        sut.viewDidLoad()
        wait(for: [firstLoaded], timeout: 1)

        guard case .loaded(let articles) = lastState else {
            return XCTFail("expected .loaded, got \(lastState)")
        }
        XCTAssertEqual(articles.map(\.id), ["cached"])
    }

    func test_viewDidLoadTriggersAnalyticsExactlyOnce() {
        repository.refreshResult = .success([])
        _ = waitForFinalState { self.sut.viewDidLoad() }
        XCTAssertEqual(repository.analyticsCalls, 1)
    }

    func test_retryReissuesNetworkRequest() {
        repository.refreshResult = .failure(URLError(.notConnectedToInternet))
        _ = waitForFinalState { self.sut.viewDidLoad() }
        let initialCalls = repository.refreshCalls

        let retried = waitForFinalState { self.sut.retry() }

        XCTAssertEqual(repository.refreshCalls, initialCalls + 1)
        if case .error = retried {} else { XCTFail("expected .error") }
    }

    // MARK: - helpers

    private func waitForFinalState(
        timeout: TimeInterval = 1,
        action: @escaping () -> Void
    ) -> NewsViewModel.State {
        let exp = expectation(description: "final state")
        var last: NewsViewModel.State = .idle
        sut.onStateChange = { [weak self] state in
            last = state
            guard let self else { return }
            if self.isTerminal(state) { exp.fulfill() }
        }
        action()
        wait(for: [exp], timeout: timeout)
        return last
    }

    private func isTerminal(_ state: NewsViewModel.State) -> Bool {
        switch state {
        case .loaded, .empty, .error: return true
        case .idle, .loading: return false
        }
    }

    private func makeArticle(id: String, title: String) -> NewsArticle {
        NewsArticle(
            id: id,
            title: title,
            abstract: "",
            source: "NYT",
            publishedAt: Date(timeIntervalSince1970: 1_750_000_000),
            articleURL: nil,
            imageURL: nil
        )
    }
}

private final class StubNewsRepository: NewsRepositoryProtocol {
    var cachedResult: CachedTopStories?
    var refreshResult: Result<[NewsArticle], Error>?
    private(set) var analyticsCalls = 0
    private(set) var refreshCalls = 0

    func getCachedTopStories() -> CachedTopStories? { cachedResult }

    func refreshTopStories(completion: @escaping (Result<[NewsArticle], Error>) -> Void) {
        refreshCalls += 1
        guard let result = refreshResult else { return }
        DispatchQueue.main.async { completion(result) }
    }

    func sendAnalyticsEvent() { analyticsCalls += 1 }
}
