//
//  FormTextFieldView.swift
//  SmartPlanner
//

import UIKit

final class FormTextFieldView: UIView, UITextFieldDelegate {

    var onTextChange: ((String) -> Void)?
    var characterLimit: Int?

    private let header: FormHeaderView
    private let textField: UITextField = {
        let field = UITextField()
        field.font = DesignTokens.Typography.value()
        field.adjustsFontForContentSizeCategory = true
        field.clearButtonMode = .whileEditing
        field.returnKeyType = .next
        field.translatesAutoresizingMaskIntoConstraints = false
        return field
    }()

    init(symbolName: String, title: String, placeholder: String, characterLimit: Int? = nil) {
        self.header = FormHeaderView(
            symbolName: symbolName,
            title: title,
            showsTrailingLabel: characterLimit != nil
        )
        self.characterLimit = characterLimit
        super.init(frame: .zero)
        textField.placeholder = placeholder
        textField.accessibilityLabel = title
        textField.delegate = self
        textField.addTarget(self, action: #selector(textChanged), for: .editingChanged)

        let stack = UIStackView(arrangedSubviews: [header, textField])
        stack.axis = .vertical
        stack.spacing = DesignTokens.Spacing.s
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        updateCounter()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    var text: String { textField.text ?? "" }

    var fieldAccessibilityIdentifier: String? {
        get { textField.accessibilityIdentifier }
        set { textField.accessibilityIdentifier = newValue }
    }

    func focus() {
        textField.becomeFirstResponder()
    }

    @objc private func textChanged() {
        if let limit = characterLimit, text.count > limit {
            textField.text = String(text.prefix(limit))
        }
        updateCounter()
        onTextChange?(text)
    }

    private func updateCounter() {
        guard let limit = characterLimit else { return }
        header.trailingLabel.text = "\(text.count)/\(limit)"
    }
}
