//
//  CreateTaskViewController.swift
//  SmartPlanner
//

import UIKit

final class CreateTaskViewController: UIViewController {

    weak var delegate: CreateTaskViewControllerDelegate?

    private enum Strings {
        static let screenTitle = "Новая задача"
        static let save = "Сохранить"

        static let titleField = "Название"
        static let titlePlaceholder = "Например, Подготовить отчёт"

        static let descriptionField = "Описание"
        static let descriptionPlaceholder = "Добавьте детали или контекст…"

        static let flagTitle = "Флаг"
        static let flagSubtitle = "Пометить задачу важной"
        static let dateTitle = "Выбрать дату"
        static let dateSubtitle = "Установить срок выполнения"

        static let tipTitle = "Совет"
        static let tipMessage = "Короткие и конкретные названия задач легче выполнять. Добавьте дату, чтобы получать напоминания."
    }

    private let viewModel: CreateTaskViewModel

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.alwaysBounceVertical = true
        view.keyboardDismissMode = .interactive
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = DesignTokens.Spacing.l
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private lazy var titleField = FormTextFieldView(
        symbolName: "doc.text",
        title: Strings.titleField,
        placeholder: Strings.titlePlaceholder,
        characterLimit: viewModel.titleCharacterLimit
    )

    private lazy var descriptionField = FormTextAreaView(
        symbolName: "text.alignleft",
        title: Strings.descriptionField,
        placeholder: Strings.descriptionPlaceholder,
        minHeight: DesignTokens.Sizing.descriptionMinHeight - DesignTokens.Spacing.xxl * 2
    )

    private let prioritySelector = PrioritySelectorView()

    private let flagRow = SettingsRowView(
        symbolName: "flag",
        title: Strings.flagTitle,
        subtitle: Strings.flagSubtitle
    )

    private let dateRow = SettingsRowView(
        symbolName: "calendar",
        title: Strings.dateTitle,
        subtitle: Strings.dateSubtitle
    )

    private let datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .inline
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()

    private lazy var datePickerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(datePicker)
        NSLayoutConstraint.activate([
            datePicker.topAnchor.constraint(equalTo: view.topAnchor, constant: DesignTokens.Spacing.s),
            datePicker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            datePicker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            datePicker.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        view.isHidden = true
        return view
    }()

    private lazy var saveButton = UIBarButtonItem(
        title: Strings.save,
        style: .done,
        target: self,
        action: #selector(saveTapped)
    )

    init(viewModel: CreateTaskViewModel = CreateTaskViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DesignTokens.Palette.screenBackground
        title = Strings.screenTitle
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.prefersLargeTitles = true

        setupNavigationBar()
        setupLayout()
        bindViewModel()
    }

    private func setupNavigationBar() {
        navigationItem.rightBarButtonItem = saveButton
        updateSaveButtonState(isValid: viewModel.isValid)
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let titleCard = CardView()
        titleCard.addArrangedSubview(titleField)

        let descriptionCard = CardView()
        descriptionCard.addArrangedSubview(descriptionField)

        let priorityCard = CardView()
        priorityCard.addArrangedSubview(prioritySelector)

        let settingsCard = CardView()
        settingsCard.addArrangedSubview(flagRow)
        settingsCard.addArrangedSubview(SeparatorView())
        settingsCard.addArrangedSubview(dateRow)
        settingsCard.addArrangedSubview(datePickerContainer)

        let tipCard = TipCardView(title: Strings.tipTitle, message: Strings.tipMessage)

        [titleCard, descriptionCard, priorityCard, settingsCard, tipCard].forEach {
            contentStack.addArrangedSubview($0)
        }

        let layoutInsets = UIEdgeInsets(
            top: DesignTokens.Spacing.l,
            left: DesignTokens.Spacing.l,
            bottom: DesignTokens.Spacing.xxl,
            right: DesignTokens.Spacing.l
        )

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: layoutInsets.top),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: layoutInsets.left),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -layoutInsets.right),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -layoutInsets.bottom),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -(layoutInsets.left + layoutInsets.right)),

            titleCard.heightAnchor.constraint(greaterThanOrEqualToConstant: DesignTokens.Sizing.titleCardMinHeight)
        ])
    }

    private func bindViewModel() {
        titleField.onTextChange = { [weak self] in self?.viewModel.updateTitle($0) }
        descriptionField.onTextChange = { [weak self] in self?.viewModel.updateDetails($0) }
        prioritySelector.onSelectionChanged = { [weak self] in self?.viewModel.updatePriority($0) }
        flagRow.onValueChanged = { [weak self] in self?.viewModel.updateFlagged($0) }
        dateRow.onValueChanged = { [weak self] in self?.handleDateSwitch(isOn: $0) }
        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)

        prioritySelector.setSelected(viewModel.priority)

        viewModel.onValidityChanged = { [weak self] isValid in
            self?.updateSaveButtonState(isValid: isValid)
        }
        viewModel.onTaskCreated = { [weak self] task in
            guard let self else { return }
            self.delegate?.createTaskViewController(self, didCreateTask: task)
            self.navigationController?.popViewController(animated: true)
        }
        viewModel.onValidationError = { [weak self] in
            self?.titleField.focus()
        }
    }

    private func updateSaveButtonState(isValid: Bool) {
        saveButton.isEnabled = isValid
    }

    private func handleDateSwitch(isOn: Bool) {
        viewModel.updateDeadlineEnabled(isOn)
        UIView.animate(withDuration: 0.25) {
            self.datePickerContainer.isHidden = !isOn
            self.datePickerContainer.alpha = isOn ? 1 : 0
            self.view.layoutIfNeeded()
        }
    }

    @objc private func dateChanged() {
        viewModel.updateDeadline(datePicker.date)
    }

    @objc private func saveTapped() {
        viewModel.save()
    }
}

