//
//  FormTextAreaView.swift
//  SmartPlanner
//

import UIKit

final class FormTextAreaView: UIView, UITextViewDelegate {

    var onTextChange: ((String) -> Void)?

    private let header: FormHeaderView
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = DesignTokens.Typography.value()
        label.textColor = DesignTokens.Palette.placeholder
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    private let textView: UITextView = {
        let view = UITextView()
        view.font = DesignTokens.Typography.value()
        view.adjustsFontForContentSizeCategory = true
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    init(symbolName: String, title: String, placeholder: String, minHeight: CGFloat) {
        self.header = FormHeaderView(symbolName: symbolName, title: title, showsTrailingLabel: false)
        super.init(frame: .zero)

        placeholderLabel.text = placeholder
        textView.accessibilityLabel = title
        textView.delegate = self

        let textContainer = UIView()
        textContainer.translatesAutoresizingMaskIntoConstraints = false
        textContainer.addSubview(textView)
        textContainer.addSubview(placeholderLabel)

        let stack = UIStackView(arrangedSubviews: [header, textContainer])
        stack.axis = .vertical
        stack.spacing = DesignTokens.Spacing.s
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            textView.topAnchor.constraint(equalTo: textContainer.topAnchor),
            textView.leadingAnchor.constraint(equalTo: textContainer.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: textContainer.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: textContainer.bottomAnchor),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: minHeight),

            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor),
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor),
            placeholderLabel.trailingAnchor.constraint(equalTo: textView.trailingAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    var text: String { textView.text ?? "" }

    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !text.isEmpty
        onTextChange?(text)
    }
}
