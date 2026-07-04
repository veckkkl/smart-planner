//
//  DashboardPalette.swift
//  SmartPlanner
//
//  Soft, pastel-ish variants of system colors used in dashboard donut
//  chart segments, calendar markers, and legend dots.

import UIKit

enum DashboardPalette {
    static let completed = UIColor.systemBlue.softened()
    static let active = UIColor.systemGreen.softened()
    static let overdue = UIColor.systemRed.softened()
    static let noDate = UIColor.systemGray.softened()
}

private extension UIColor {
    func softened() -> UIColor {
        UIColor { trait in
            let base = self.resolvedColor(with: trait)
            var hue: CGFloat = 0, saturation: CGFloat = 0, brightness: CGFloat = 0, alpha: CGFloat = 0
            guard base.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
                return base
            }
            let isDark = trait.userInterfaceStyle == .dark
            let newSaturation = isDark ? saturation * 0.85 : saturation * 0.72
            let newBrightness = isDark ? min(brightness * 1.05, 1) : min(brightness * 1.10, 1)
            return UIColor(hue: hue, saturation: newSaturation, brightness: newBrightness, alpha: alpha)
        }
    }
}
