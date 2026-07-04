//
//  TasksFlowUITests.swift
//  SmartPlannerUITests
//

import XCTest

final class TasksFlowUITests: XCTestCase {

    private enum TestData {
        static let title = "UI Test Task"
        static let description = "Created from UI test"
        static let waitTimeout: TimeInterval = 5
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-UITests"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    func test_createTask_appearsInList_andTogglesCompleted() throws {
        try goToTasksTab()
        try openCreateTaskScreen()
        try fillForm(title: TestData.title, description: TestData.description)
        try selectHighPriority()
        try enableFlag()
        try saveTask()
        try verifyTaskAppearsInList(title: TestData.title)
        try toggleCompletion(title: TestData.title)
    }

    // MARK: - flow steps

    private func goToTasksTab() throws {
        let tab = app.tabBars.buttons["tasks.tab"]
        XCTAssertTrue(tab.waitForExistence(timeout: TestData.waitTimeout), "Tasks tab not found")
        tab.tap()
    }

    private func openCreateTaskScreen() throws {
        let addButton = app.buttons["tasks.addButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: TestData.waitTimeout), "Add button not found")
        addButton.tap()
    }

    private func fillForm(title: String, description: String) throws {
        let titleField = app.textFields["createTask.titleField"]
        XCTAssertTrue(titleField.waitForExistence(timeout: TestData.waitTimeout), "Title field not found")
        titleField.tap()
        titleField.typeText(title)

        let descriptionField = app.textViews["createTask.descriptionField"]
        XCTAssertTrue(descriptionField.waitForExistence(timeout: TestData.waitTimeout), "Description field not found")
        descriptionField.tap()
        descriptionField.typeText(description)
    }

    private func selectHighPriority() throws {
        let button = app.buttons["createTask.priority.high"]
        XCTAssertTrue(button.waitForExistence(timeout: TestData.waitTimeout), "High priority button not found")
        button.tap()
    }

    private func enableFlag() throws {
        let toggle = app.switches["createTask.flagSwitch"]
        XCTAssertTrue(toggle.waitForExistence(timeout: TestData.waitTimeout), "Flag switch not found")
        toggle.tap()
    }

    private func saveTask() throws {
        let save = app.buttons["createTask.saveButton"]
        XCTAssertTrue(save.waitForExistence(timeout: TestData.waitTimeout), "Save button not found")
        XCTAssertTrue(save.isEnabled, "Save button must be enabled when title is non-empty")
        save.tap()
    }

    private func verifyTaskAppearsInList(title: String) throws {
        let cellTitle = app.staticTexts["taskCell.title.\(title)"]
        XCTAssertTrue(cellTitle.waitForExistence(timeout: TestData.waitTimeout), "Created task did not appear in list")
    }

    private func toggleCompletion(title: String) throws {
        let completeButton = app.buttons["taskCell.completeButton.\(title)"]
        XCTAssertTrue(completeButton.waitForExistence(timeout: TestData.waitTimeout), "Complete button not found")
        XCTAssertEqual(completeButton.value as? String, "не выполнено", "Task should start in not-completed state")

        completeButton.tap()

        let completedPredicate = NSPredicate(format: "value == %@", "выполнено")
        let completedExpectation = expectation(for: completedPredicate, evaluatedWith: completeButton, handler: nil)
        wait(for: [completedExpectation], timeout: TestData.waitTimeout)
    }
}
