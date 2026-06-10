//
//  RenderManager.swift
//  Lacquer Art - Graphics Rendering Manager
//

import SwiftUI

/// Render Manager (code-generated visual elements)
class RenderManager {
    static let shared = RenderManager()

    private init() {}

    // MARK: - Gradient Generation

    /// Generate lacquer bowl gradient
    func lacquerBowlGradient(for type: LacquerType) -> RadialGradient {
        let colors: [Color]

        switch type {
        case .black:
            colors = [
                Color(red: 0.15, green: 0.15, blue: 0.15),
                Color(red: 0.08, green: 0.08, blue: 0.08),
                Color(red: 0.05, green: 0.05, blue: 0.05)
            ]
        case .red:
            colors = [
                Color(red: 0.9, green: 0.2, blue: 0.2),
                Color(red: 0.75, green: 0.1, blue: 0.1),
                Color(red: 0.6, green: 0.05, blue: 0.05)
            ]
        case .gold:
            colors = [
                Color(red: 0.95, green: 0.75, blue: 0.23),
                Color(red: 0.85, green: 0.65, blue: 0.13),
                Color(red: 0.75, green: 0.55, blue: 0.08)
            ]
        case .vermillion:
            colors = [
                Color(red: 1.0, green: 0.3, blue: 0.2),
                Color(red: 0.95, green: 0.2, blue: 0.15),
                Color(red: 0.85, green: 0.15, blue: 0.1)
            ]
        case .green:
            colors = [
                Color(red: 0.3, green: 0.7, blue: 0.4),
                Color(red: 0.2, green: 0.6, blue: 0.3),
                Color(red: 0.15, green: 0.5, blue: 0.25)
            ]
        case .blue:
            colors = [
                Color(red: 0.25, green: 0.5, blue: 0.8),
                Color(red: 0.15, green: 0.4, blue: 0.7),
                Color(red: 0.1, green: 0.3, blue: 0.6)
            ]
        case .yellow:
            colors = [
                Color(red: 1.0, green: 0.85, blue: 0.3),
                Color(red: 0.9, green: 0.75, blue: 0.2),
                Color(red: 0.8, green: 0.65, blue: 0.15)
            ]
        case .brown:
            colors = [
                Color(red: 0.55, green: 0.4, blue: 0.3),
                Color(red: 0.45, green: 0.3, blue: 0.2),
                Color(red: 0.35, green: 0.25, blue: 0.15)
            ]
        default:
            colors = [
                type.color.opacity(0.8),
                type.color,
                type.color.opacity(1.2)
            ]
        }

        return RadialGradient(
            colors: colors,
            center: .center,
            startRadius: 20,
            endRadius: 80
        )
    }

    /// Generate wood texture gradient
    func woodGrainGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.65, green: 0.50, blue: 0.39),
                Color(red: 0.55, green: 0.42, blue: 0.33),
                Color(red: 0.60, green: 0.47, blue: 0.37),
                Color(red: 0.52, green: 0.40, blue: 0.31)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Generate metallic luster gradient
    func metallicGradient() -> LinearGradient {
        LinearGradient(
            colors: [
                Color(white: 0.7),
                Color(white: 0.9),
                Color(white: 0.85),
                Color(white: 0.75)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Generate lacquer surface gloss effect
    func lacquerGloss(glossiness: Double) -> some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(glossiness * 0.4),
                        Color.clear,
                        Color.white.opacity(glossiness * 0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .blendMode(.overlay)
    }

    // MARK: - Shape Generation

    /// Generate fan shape path
    func fanShape(spread: Double = 120, radius: CGFloat = 150) -> Path {
        var path = Path()

        let center = CGPoint(x: radius, y: radius)
        let startAngle = Angle(degrees: -spread / 2)
        let endAngle = Angle(degrees: spread / 2)

        path.move(to: center)
        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )
        path.closeSubpath()

        return path
    }

    /// Generate single fan bone path
    func fanBonePath(length: CGFloat = 150, width: CGFloat = 8) -> Path {
        var path = Path()

        // Fan bone from bottom to top, slightly curved
        let controlPoint1 = CGPoint(x: width * 0.3, y: length * 0.3)
        let controlPoint2 = CGPoint(x: width * 0.5, y: length * 0.7)
        let endPoint = CGPoint(x: width * 0.5, y: length)

        path.move(to: CGPoint(x: 0, y: 0))
        path.addCurve(
            to: endPoint,
            control1: controlPoint1,
            control2: controlPoint2
        )
        path.addLine(to: CGPoint(x: width, y: length))
        path.addCurve(
            to: CGPoint(x: width, y: 0),
            control1: CGPoint(x: width * 1.5, y: length * 0.7),
            control2: CGPoint(x: width * 1.3, y: length * 0.3)
        )
        path.closeSubpath()

        return path
    }

    /// Generate cloud pattern
    func cloudPattern(in rect: CGRect) -> Path {
        var path = Path()

        let centerX = rect.midX
        let centerY = rect.midY
        let radius = min(rect.width, rect.height) * 0.3

        // Generate scroll cloud shape
        for i in 0..<3 {
            let angle = Double(i) * 120.0
            let x = centerX + cos(angle * .pi / 180) * radius
            let y = centerY + sin(angle * .pi / 180) * radius

            path.addEllipse(in: CGRect(
                x: x - radius * 0.4,
                y: y - radius * 0.4,
                width: radius * 0.8,
                height: radius * 0.8
            ))
        }

        return path
    }

    /// Generate scroll grass pattern
    func scrollPattern(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height
        let amplitude = height * 0.3
        let frequency = 2.0

        path.move(to: CGPoint(x: 0, y: height / 2))

        for x in stride(from: 0, through: width, by: 2) {
            let y = height / 2 + sin(x / width * frequency * 2 * .pi) * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }

    // MARK: - Background Generation

    /// Generate ink wash background
    func inkWashBackground() -> some View {
        ZStack {
            // Base paper color
            Color(red: 0.95, green: 0.94, blue: 0.90)

            // Ink wash effect
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.black.opacity(0.02),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(
                        x: CGFloat.random(in: -200...200),
                        y: CGFloat.random(in: -200...200)
                    )
            }
        }
        .ignoresSafeArea()
    }

    /// Generate desk background
    func studioDeskBackground() -> some View {
        ZStack {
            // wall
            Color(red: 0.88, green: 0.85, blue: 0.82)

            // wooden desk
            RoundedRectangle(cornerRadius: 20)
                .fill(woodGrainGradient())
                .frame(height: 300)
                .offset(y: 300)
        }
        .ignoresSafeArea()
    }

    // MARK: - Animation Helpers

    /// Generate droplet animation path
    func dropletPath(progress: Double, in rect: CGRect) -> Path {
        var path = Path()

        let startY = rect.minY
        let endY = rect.maxY
        let currentY = startY + (endY - startY) * progress

        // droplet shape
        let dropSize: CGFloat = 8
        path.addEllipse(in: CGRect(
            x: rect.midX - dropSize / 2,
            y: currentY - dropSize,
            width: dropSize,
            height: dropSize * 1.5
        ))

        return path
    }
}