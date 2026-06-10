//
//  Extensions.swift
//  Lacquer Art - Swift Extensions
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    /// Create color from hexadecimal
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    /// Adjust brightness
    func brightness(_ amount: Double) -> Color {
        return self.opacity(amount)
    }
}

// MARK: - CGPoint Extensions
extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }

    /// Calculate distance to another point
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }

    /// Calculate midpoint
    func midPoint(to point: CGPoint) -> CGPoint {
        return CGPoint(x: (x + point.x) / 2, y: (y + point.y) / 2)
    }
}

// MARK: - View Extensions
extension View {
    /// Conditional modifier
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Conditional modifier (with else branch)
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }

    /// Add glow effect
    func glow(color: Color = .white, radius: CGFloat = 10) -> some View {
        self
            .shadow(color: color.opacity(0.6), radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.4), radius: radius * 2, x: 0, y: 0)
    }

    /// Poem display style
    func poemStyle() -> some View {
        self
            .font(AppFonts.poem())
            .foregroundColor(AppColors.inkBlack)
            .multilineTextAlignment(.center)
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppColors.paperWhite.opacity(0.9))
                    .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
            )
    }

    /// Ink painting border style
    func inkBorder() -> some View {
        self
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(AppColors.inkBlack.opacity(0.3), lineWidth: 2)
            )
    }
}

// MARK: - Animation Extensions
extension Animation {
    /// Spring animation (light)
    static var lightSpring: Animation {
        .spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)
    }

    /// Spring animation (soft)
    static var softSpring: Animation {
        .spring(response: 0.8, dampingFraction: 0.8, blendDuration: 0)
    }

    /// Ease in-out (quick)
    static var quickEase: Animation {
        .easeInOut(duration: 0.3)
    }

    /// Ease in-out (slow)
    static var slowEase: Animation {
        .easeInOut(duration: 0.8)
    }
}

// MARK: - Path Extensions
extension Path {
    /// Smooth path (using Bezier curves)
    static func smoothPath(through points: [CGPoint]) -> Path {
        guard points.count > 1 else {
            return Path()
        }

        var path = Path()
        path.move(to: points[0])

        if points.count == 2 {
            path.addLine(to: points[1])
            return path
        }

        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]
            let midPoint = CGPoint(
                x: (current.x + previous.x) / 2,
                y: (current.y + previous.y) / 2
            )

            if i == 1 {
                path.addLine(to: midPoint)
            } else {
                let previousMid = CGPoint(
                    x: (previous.x + points[i - 2].x) / 2,
                    y: (previous.y + points[i - 2].y) / 2
                )
                path.addQuadCurve(to: midPoint, control: previous)
            }

            if i == points.count - 1 {
                path.addLine(to: current)
            }
        }

        return path
    }
}

// MARK: - Double Extensions
extension Double {
    /// Clamp to range
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }

    /// Convert to percentage string
    func toPercentage() -> String {
        return String(format: "%.0f%%", self * 100)
    }
}

// MARK: - Int Extensions
extension Int {
    /// Convert to English number words
    func toEnglishWords() -> String {
        let numberWords = ["zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]

        if self >= 0 && self < numberWords.count {
            return numberWords[self]
        }

        return "\(self)"
    }
}