//
//  DesignTokens.swift
//  SmartPlanner
//

import UIKit

enum DesignTokens {

    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
    }

    enum Radius {
        static let card: CGFloat = 20
        static let control: CGFloat = 14
        static let capsule: CGFloat = 22
    }

    enum Sizing {
        static let titleCardMinHeight: CGFloat = 92
        static let descriptionMinHeight: CGFloat = 160
        static let iconSize: CGFloat = 22
        static let priorityButtonHeight: CGFloat = 44
        static let separatorHeight: CGFloat = 1.0 / UIScreen.main.scale
    }

    enum Shadow {
        static let opacity: Float = 0.06
        static let radius: CGFloat = 12
        static let offset = CGSize(width: 0, height: 4)
    }

    enum Palette {
        static let accent = UIColor.systemBlue
        static let cardBackground = UIColor.secondarySystemGroupedBackground
        static let screenBackground = UIColor.systemGroupedBackground
        static let separator = UIColor.separator
        static let tipBackground = UIColor.systemBlue.withAlphaComponent(0.12)
        static let primaryText = UIColor.label
        static let secondaryText = UIColor.secondaryLabel
        static let placeholder = UIColor.placeholderText
    }

    enum Typography {
        static func cardTitle() -> UIFont {
            UIFont.preferredFont(forTextStyle: .subheadline).withWeight(.semibold)
        }
        static func value() -> UIFont {
            UIFont.preferredFont(forTextStyle: .body)
        }
        static func caption() -> UIFont {
            UIFont.preferredFont(forTextStyle: .footnote)
        }
        static func sectionTitle() -> UIFont {
            UIFont.preferredFont(forTextStyle: .headline)
        }
    }
}

private extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        let descriptor = fontDescriptor.addingAttributes([
            .traits: [UIFontDescriptor.TraitKey.weight: weight]
        ])
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
