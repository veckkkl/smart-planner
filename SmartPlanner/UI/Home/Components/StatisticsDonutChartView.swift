//
//  StatisticsDonutChartView.swift
//  SmartPlanner
//

import UIKit

struct DonutSegment {
    let value: Int
    let color: UIColor
}

final class StatisticsDonutChartView: UIView {

    private enum Constants {
        static let lineWidthRatio: CGFloat = 0.16
        static let preferredSize: CGFloat = 160
        static let animationDuration: CFTimeInterval = 0.45
        static let placeholderAlpha: CGFloat = 0.18
    }

    private var segmentLayers: [CAShapeLayer] = []
    private let placeholderLayer = CAShapeLayer()

    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .largeTitle).withWeight(.bold)
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        label.textAlignment = .center
        label.text = "всего"
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        layer.addSublayer(placeholderLayer)
        placeholderLayer.fillColor = UIColor.clear.cgColor
        placeholderLayer.strokeColor = UIColor.systemGray5.cgColor

        let centerStack = UIStackView(arrangedSubviews: [totalLabel, captionLabel])
        centerStack.axis = .vertical
        centerStack.alignment = .center
        centerStack.spacing = 0
        centerStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(centerStack)
        NSLayoutConstraint.activate([
            centerStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            centerStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            heightAnchor.constraint(equalToConstant: Constants.preferredSize),
            widthAnchor.constraint(equalToConstant: Constants.preferredSize)
        ])
        isAccessibilityElement = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutPlaceholder()
        layoutSegments()
    }

    func update(total: Int, segments: [DonutSegment]) {
        totalLabel.text = "\(total)"
        let nonZero = segments.filter { $0.value > 0 }

        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers = nonZero.map { segment in
            let layer = CAShapeLayer()
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = segment.color.cgColor
            layer.lineCap = .butt
            self.layer.addSublayer(layer)
            return layer
        }

        placeholderLayer.opacity = nonZero.isEmpty ? 1 : Float(Constants.placeholderAlpha)
        layoutSegments(segments: nonZero, animated: window != nil)
        accessibilityLabel = "Всего \(total) задач"
    }

    private func layoutPlaceholder() {
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
        placeholderLayer.path = path.cgPath
        placeholderLayer.lineWidth = lineWidth
    }

    private var lineWidth: CGFloat {
        min(bounds.width, bounds.height) * Constants.lineWidthRatio
    }

    private func layoutSegments() {
        layoutSegments(segments: nil, animated: false)
    }

    private func layoutSegments(segments: [DonutSegment]?, animated: Bool) {
        guard !segmentLayers.isEmpty else { return }
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let segs = segments ?? currentSegments
        let total = max(segs.reduce(0) { $0 + $1.value }, 1)

        var startAngle: CGFloat = -.pi / 2
        for (index, segment) in segs.enumerated() {
            guard index < segmentLayers.count else { break }
            let proportion = CGFloat(segment.value) / CGFloat(total)
            let endAngle = startAngle + proportion * .pi * 2
            let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            let layer = segmentLayers[index]
            layer.lineWidth = lineWidth
            if animated {
                let anim = CABasicAnimation(keyPath: "path")
                anim.duration = Constants.animationDuration
                anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                anim.fromValue = layer.path ?? path.cgPath
                anim.toValue = path.cgPath
                layer.add(anim, forKey: "pathAnim")
            }
            layer.path = path.cgPath
            startAngle = endAngle
        }
        currentSegments = segs
    }

    private var currentSegments: [DonutSegment] = []
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
