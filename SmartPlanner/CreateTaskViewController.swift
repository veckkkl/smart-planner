//
//  CreateTaskViewController.swift
//  SmartPlanner
//
//  Created by valentina balde on 11/30/25.
//

import UIKit

final class CreateTaskViewController: UIViewController {

    weak var delegate: CreateTaskViewControllerDelegate?

    private let titleTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Название задачи *"
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.systemGray4.cgColor
        textField.layer.cornerRadius = 8
        textField.font = .systemFont(ofSize: 15)
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.layer.cornerRadius = 8
        textView.font = .systemFont(ofSize: 15)
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()


    private let prioritySegmentedControl: UISegmentedControl = {
        let items = ["Низкий", "Средний", "Высокий"]
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = TaskPriority.medium.rawValue
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let flagSwitch: UISwitch = {
        let flagSwitch = UISwitch()
        flagSwitch.translatesAutoresizingMaskIntoConstraints = false
        return flagSwitch
    }()

    private let deadlineSwitch: UISwitch = {
        let deadlineSwitch = UISwitch()
        deadlineSwitch.translatesAutoresizingMaskIntoConstraints = false
        return deadlineSwitch
    }()

    private let deadlineDatePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.isHidden = true
        return picker
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Новая задача"

        setupNavigationBar()
        setupLayout()
        setupActions()
    }

    private func setupNavigationBar() {
        let saveButton = UIBarButtonItem(
            title: "Сохранить",
            style: .done,
            target: self,
            action: #selector(saveTapped)
        )
        navigationItem.rightBarButtonItem = saveButton
    }

    private func setupLayout() {
        let flagRow = makeRow(title: "Флаг", rightView: flagSwitch)
        let deadlineRow = makeRow(title: "Выбрать дату", rightView: deadlineSwitch)

        let stack = UIStackView(arrangedSubviews: [
            titleTextField,
            descriptionTextView,
            prioritySegmentedControl,
            flagRow,
            deadlineRow
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        view.addSubview(deadlineDatePicker)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            descriptionTextView.heightAnchor.constraint(equalToConstant: 80),

            deadlineDatePicker.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 8),
            deadlineDatePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }

    private func makeRow(title: String, rightView: UIView) -> UIView {
        let label = UILabel()
        label.text = title

        let stack = UIStackView(arrangedSubviews: [label, rightView])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        return stack
    }

    private func setupActions() {
        deadlineSwitch.addTarget(self, action: #selector(deadlineSwitchChanged), for: .valueChanged)
    }

    @objc
    private func deadlineSwitchChanged() {
        deadlineDatePicker.isHidden = deadlineSwitch.isOn == false
    }

    @objc
    private func saveTapped() {
        // название – обязательное поле
        guard let title = titleTextField.text,
              title.isEmpty == false
        else {
            // можно позже добавить alert
            return
        }

        let description = descriptionTextView.text
        let priorityIndex = prioritySegmentedControl.selectedSegmentIndex
        let priority = TaskPriority(rawValue: priorityIndex) ?? .medium
        let isFlagged = flagSwitch.isOn
        let deadline = deadlineSwitch.isOn ? deadlineDatePicker.date : nil

        let task = Task(
            title: title,
            details: description?.isEmpty == true ? nil : description,
            priority: priority,
            isFlagged: isFlagged,
            deadline: deadline
        )

        delegate?.createTaskViewController(self, didCreateTask: task)
        navigationController?.popViewController(animated: true)
    }
}
