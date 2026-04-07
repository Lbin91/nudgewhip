// DesignTokens.swift
// design-system.md v0.1 기준 컬러·스페이싱·반경·모션 토큰.

import SwiftUI

extension NSColor {
    convenience init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255
        let g = CGFloat((rgb >> 8) & 0xFF) / 255
        let b = CGFloat(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}

// MARK: - Color Tokens

extension Color {
    private static func adaptive(light: String, dark: String) -> Color {
        Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
 let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light)
        }))
    }

    static let nudgewhipBgCanvas = adaptive(light: "#F7F3EC", dark: "#0F1318")
    static let nudgewhipBgSurface = adaptive(light: "#FFFDF9", dark: "#161C23")
    static let nudgewhipBgSurfaceAlt = adaptive(light: "#F2EDE4", dark: "#1B222B")

    static let nudgewhipTextPrimary = adaptive(light: "#141A21", dark: "#F5F7FA")
    static let nudgewhipTextSecondary = adaptive(light: "#596273", dark: "#A7B0BF")
    static let nudgewhipTextMuted = adaptive(light: "#5F6D82", dark: "#758095")

    static let nudgewhipFocus = adaptive(light: "#167A6C", dark: "#47C4B0")
    static let nudgewhipRest = adaptive(light: "#5C7E52", dark: "#8CBB7E")
    static let nudgewhipAlert = adaptive(light: "#B84525", dark: "#FF8A68")
    static let nudgewhipAccent = adaptive(light: "#D8A23A", dark: "#F2C86A")

    static let nudgewhipStrokeDefault = adaptive(light: "#D7D0C6", dark: "#2A3440")
    static let nudgewhipStrokeStrong = adaptive(light: "#B8B0A2", dark: "#3A4656")
}

// MARK: - Content State → Color

enum NudgeWhipContentStateColor {
    static let focus = Color.nudgewhipFocus
    static let idleDetected = Color.nudgewhipFocus.opacity(0.6)
    static let gentleNudge = Color.nudgewhipFocus
    static let strongNudge = Color.nudgewhipAlert
    static let recovery = Color.nudgewhipFocus
    static let rest = Color.nudgewhipRest
    static let remoteEscalation = Color.nudgewhipAlert
}

// MARK: - Spacing

enum NudgeWhipSpacing {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24
    static let s6: CGFloat = 32
    static let s7: CGFloat = 48
}

// MARK: - Radius

enum NudgeWhipRadius {
    static let `default`: CGFloat = 12
    static let card: CGFloat = 16
    static let popover: CGFloat = 18
    static let button: CGFloat = 10
}

// MARK: - Motion

enum NudgeWhipMotion {
    static let fast: Duration = .milliseconds(120)
    static let base: Duration = .milliseconds(180)
    static let slow: Duration = .milliseconds(260)
    static let alert: Duration = .milliseconds(320)
    static let recovery: Duration = .milliseconds(220)
}

// MARK: - Layout

enum NudgeWhipLayout {
    static let popoverWidth: CGFloat = 360
}
