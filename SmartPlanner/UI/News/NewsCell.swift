//
//  NewsCell.swift
//  SmartPlanner
//
//  Created by valentina balde on 3/16/26.
//

import UIKit

final class NewsCell: UITableViewCell {

    static let reuseIdentifier = "NewsCell"

    private let previewImageView = UIImageView()
    private let imagePlaceholderIcon = UIImageView()
    private let imageLoadingIndicator = UIActivityIndicatorView(style: .medium)

    private let titleLabel = UILabel()
    private let abstractLabel = UILabel()
    private let sourceLabel = UILabel()
    private let dateLabel = UILabel()

    private var currentImageTask: ImageLoadTask?
    private var currentImageURL: URL?

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        currentImageTask?.cancel()
        currentImageTask = nil
        currentImageURL = nil

        previewImageView.image = nil
        previewImageView.backgroundColor = UIColor.secondarySystemFill
        imagePlaceholderIcon.isHidden = false
        imagePlaceholderIcon.image = UIImage(systemName: "photo")
        imageLoadingIndicator.stopAnimating()

        titleLabel.text = nil
        abstractLabel.text = nil
        sourceLabel.text = nil
        dateLabel.text = nil
    }

    func configure(with article: NewsArticle, imageLoader: ImageLoader = .shared) {
        titleLabel.text = article.title
        abstractLabel.text = article.abstract.isEmpty ? "Без описания" : article.abstract
        sourceLabel.text = article.source
        dateLabel.text = Self.dateFormatter.string(from: article.publishedAt)

        loadImage(url: article.imageURL, imageLoader: imageLoader)
    }

    private func loadImage(url: URL?, imageLoader: ImageLoader) {
        currentImageTask?.cancel()
        currentImageTask = nil
        currentImageURL = url

        guard let url else {
            showNoImagePlaceholder()
            return
        }

        showLoadingPlaceholder()

        currentImageTask = imageLoader.loadImage(from: url) { [weak self] image in
            guard let self else { return }
            guard self.currentImageURL == url else { return }

            if let image {
                self.previewImageView.image = image
                self.previewImageView.backgroundColor = .clear
                self.imagePlaceholderIcon.isHidden = true
                self.imageLoadingIndicator.stopAnimating()
            } else {
                self.showFailedImagePlaceholder()
            }
        }
    }

    private func showLoadingPlaceholder() {
        previewImageView.image = nil
        previewImageView.backgroundColor = UIColor.secondarySystemFill
        imagePlaceholderIcon.isHidden = true
        imageLoadingIndicator.startAnimating()
    }

    private func showNoImagePlaceholder() {
        previewImageView.image = nil
        previewImageView.backgroundColor = UIColor.secondarySystemFill
        imagePlaceholderIcon.isHidden = false
        imagePlaceholderIcon.image = UIImage(systemName: "photo")
        imageLoadingIndicator.stopAnimating()
    }

    private func showFailedImagePlaceholder() {
        previewImageView.image = nil
        previewImageView.backgroundColor = UIColor.secondarySystemFill
        imagePlaceholderIcon.isHidden = false
        imagePlaceholderIcon.image = UIImage(systemName: "exclamationmark.triangle")
        imageLoadingIndicator.stopAnimating()
    }

    private func setupUI() {
        selectionStyle = .none
        contentView.backgroundColor = .systemBackground

        previewImageView.translatesAutoresizingMaskIntoConstraints = false
        previewImageView.clipsToBounds = true
        previewImageView.contentMode = .scaleAspectFill
        previewImageView.layer.cornerRadius = 12
        previewImageView.backgroundColor = UIColor.secondarySystemFill

        imagePlaceholderIcon.translatesAutoresizingMaskIntoConstraints = false
        imagePlaceholderIcon.tintColor = .tertiaryLabel
        imagePlaceholderIcon.image = UIImage(systemName: "photo")

        imageLoadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        imageLoadingIndicator.hidesWhenStopped = true

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.numberOfLines = 0

        abstractLabel.translatesAutoresizingMaskIntoConstraints = false
        abstractLabel.font = .systemFont(ofSize: 15)
        abstractLabel.textColor = .secondaryLabel
        abstractLabel.numberOfLines = 0

        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.font = .systemFont(ofSize: 13, weight: .medium)
        sourceLabel.textColor = .tertiaryLabel

        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .tertiaryLabel
        dateLabel.textAlignment = .right

        let metaStack = UIStackView(arrangedSubviews: [sourceLabel, dateLabel])
        metaStack.axis = .horizontal
        metaStack.alignment = .fill
        metaStack.distribution = .fill
        metaStack.spacing = 8
        metaStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(previewImageView)
        previewImageView.addSubview(imagePlaceholderIcon)
        previewImageView.addSubview(imageLoadingIndicator)
        contentView.addSubview(titleLabel)
        contentView.addSubview(abstractLabel)
        contentView.addSubview(metaStack)

        NSLayoutConstraint.activate([
            previewImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            previewImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            previewImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previewImageView.heightAnchor.constraint(equalToConstant: 190),

            imagePlaceholderIcon.centerXAnchor.constraint(equalTo: previewImageView.centerXAnchor),
            imagePlaceholderIcon.centerYAnchor.constraint(equalTo: previewImageView.centerYAnchor),
            imagePlaceholderIcon.widthAnchor.constraint(equalToConstant: 26),
            imagePlaceholderIcon.heightAnchor.constraint(equalToConstant: 22),

            imageLoadingIndicator.centerXAnchor.constraint(equalTo: previewImageView.centerXAnchor),
            imageLoadingIndicator.centerYAnchor.constraint(equalTo: previewImageView.centerYAnchor),

            titleLabel.topAnchor.constraint(equalTo: previewImageView.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            abstractLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            abstractLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            abstractLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            metaStack.topAnchor.constraint(equalTo: abstractLabel.bottomAnchor, constant: 10),
            metaStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            metaStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            metaStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])

        sourceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        dateLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }
}
