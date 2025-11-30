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
        textField.placeholder = "Название задачи"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Новая задача"

        setupNavigationBar()
        setupLayout()
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
        view.addSubview(titleTextField)

        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: 16
            ),
            titleTextField.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: 16
            ),
            titleTextField.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -16
            ),
            titleTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc
    private func saveTapped() {
        guard let text = titleTextField.text,
              text.isEmpty == false
        else {
            return
        }

        let task = Task(title: text)
        delegate?.createTaskViewController(self, didCreateTask: task)
        navigationController?.popViewController(animated: true)
    }
}
