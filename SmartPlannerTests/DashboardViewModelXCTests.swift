//
//  DashboardViewModelXCTests.swift
//  SmartPlannerTests
//

import XCTest
@testable import SmartPlanner

final class DashboardViewModelXCTests: XCTestCase {

    private let fixedNow = Date(timeIntervalSince1970: 1_750_000_000)
    private let calendar = Calendar(identifier: .gregorian)

    func testInitialState() {
        let sut = DashboardViewModel(
            repository: DashboardRepositoryFake(tasks: []),
            service: DashboardServiceFake()
        )

        XCTAssertEqual(sut.statistics, .empty)
        XCTAssertTrue(sut.upcoming.isEmpty)
        XCTAssertFalse(sut.hasAnyTasks)
        XCTAssertEqual(sut.period, .week)
    }

    func testStartLoadsDashboardState() {
        let task = makeTask(title: "today", deadlineOffset: 60)
        let sut = DashboardViewModel(
            repository: DashboardRepositoryFake(tasks: [task]),
            service: DashboardStatisticsService(calendar: calendar, now: { self.fixedNow }),
            calendar: calendar,
            now: { self.fixedNow }
        )
        var renderCount = 0
        sut.onStateChanged = { renderCount += 1 }

        sut.start()

        XCTAssertTrue(sut.hasAnyTasks)
        XCTAssertEqual(sut.statistics.total, 1)
        XCTAssertEqual(sut.upcoming.map(\.title), ["today"])
        XCTAssertEqual(renderCount, 1)
        sut.stop()
    }

    func testStatisticsComeFromService() {
        let task = makeTask(title: "task")
        let expectedStatistics = DashboardStatistics(
            total: 7,
            completed: 2,
            active: 3,
            overdue: 1,
            withoutDate: 1,
            byPriority: [.low: 1, .medium: 2, .high: 4]
        )
        let service = DashboardServiceFake(statistics: expectedStatistics)
        let sut = DashboardViewModel(
            repository: DashboardRepositoryFake(tasks: [task]),
            service: service
        )

        sut.start()

        XCTAssertEqual(sut.statistics, expectedStatistics)
        XCTAssertEqual(service.receivedStatisticsPeriods, [.week])
        XCTAssertEqual(service.receivedStatisticsTasks.first?.map(\.id), [task.id])
        sut.stop()
    }

    func testUpcomingTasksComeFromService() {
        let stored = makeTask(title: "stored")
        let upcoming = [
            makeTask(title: "soon", deadlineOffset: 60),
            makeTask(title: "later", deadlineOffset: 120)
        ]
        let service = DashboardServiceFake(upcoming: upcoming)
        let sut = DashboardViewModel(
            repository: DashboardRepositoryFake(tasks: [stored]),
            service: service
        )

        sut.start()

        XCTAssertEqual(sut.upcoming.map(\.title), ["soon", "later"])
        XCTAssertEqual(service.receivedUpcomingLimits, [DashboardViewModel.Constants.upcomingLimit])
        sut.stop()
    }

    func testMarkerForSelectedDayReflectsTaskStates() {
        let tasks = [
            makeTask(title: "done", isCompleted: true, deadlineOffset: -60),
            makeTask(title: "overdue", deadlineOffset: -30),
            makeTask(title: "active", deadlineOffset: 60)
        ]
        let sut = makeRealServiceSUT(tasks: tasks)

        sut.start()
        let marker = sut.marker(for: fixedNow)

        XCTAssertEqual(marker, DayMarker(hasActive: true, hasCompleted: true, hasOverdue: true))
        sut.stop()
    }

    func testTasksForSelectedDayArePreparedForDayDetailsScreen() {
        let tasks = [
            makeTask(title: "today", deadlineOffset: 60),
            makeTask(title: "tomorrow", deadlineOffset: 24 * 60 * 60)
        ]
        let sut = makeRealServiceSUT(tasks: tasks)

        sut.start()
        let selectedTasks = sut.tasks(on: fixedNow)

        XCTAssertEqual(selectedTasks.map(\.title), ["today"])
        sut.stop()
    }

    private func makeRealServiceSUT(tasks: [Task]) -> DashboardViewModel {
        DashboardViewModel(
            repository: DashboardRepositoryFake(tasks: tasks),
            service: DashboardStatisticsService(calendar: calendar, now: { self.fixedNow }),
            calendar: calendar,
            now: { self.fixedNow }
        )
    }

    private func makeTask(
        title: String,
        isCompleted: Bool = false,
        deadlineOffset: TimeInterval? = nil
    ) -> Task {
        Task(
            title: title,
            priority: .medium,
            isFlagged: false,
            deadline: deadlineOffset.map { fixedNow.addingTimeInterval($0) },
            isCompleted: isCompleted,
            createdAt: fixedNow
        )
    }
}

private final class DashboardRepositoryFake: TaskRepositoryProtocol {
    private let tasks: [Task]
    private var observers: [ObjectIdentifier: ([Task]) -> Void] = [:]

    init(tasks: [Task]) {
        self.tasks = tasks
    }

    func save(_ task: Task) {}
    func update(_ task: Task) {}
    func delete(id: Task.ID) {}

    func fetchAll() -> [Task] {
        tasks
    }

    func addObserver(_ observer: AnyObject, onChange: @escaping ([Task]) -> Void) {
        observers[ObjectIdentifier(observer)] = onChange
        onChange(tasks)
    }

    func removeObserver(_ observer: AnyObject) {
        observers.removeValue(forKey: ObjectIdentifier(observer))
    }
}

private final class DashboardServiceFake: DashboardStatisticsServicing {
    private let statisticsResult: DashboardStatistics
    private let upcomingResult: [Task]

    private(set) var receivedStatisticsTasks: [[Task]] = []
    private(set) var receivedStatisticsPeriods: [DashboardPeriod] = []
    private(set) var receivedUpcomingLimits: [Int] = []

    init(
        statistics: DashboardStatistics = .empty,
        upcoming: [Task] = []
    ) {
        self.statisticsResult = statistics
        self.upcomingResult = upcoming
    }

    func statistics(for tasks: [Task], period: DashboardPeriod) -> DashboardStatistics {
        receivedStatisticsTasks.append(tasks)
        receivedStatisticsPeriods.append(period)
        return statisticsResult
    }

    func upcoming(from tasks: [Task], limit: Int) -> [Task] {
        receivedUpcomingLimits.append(limit)
        return upcomingResult
    }

    func tasksByDay(_ tasks: [Task]) -> [Date: [Task]] {
        [:]
    }

    func tasks(on day: Date, from tasks: [Task]) -> [Task] {
        []
    }
}
