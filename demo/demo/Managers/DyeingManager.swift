//
//  DyeingManager.swift
//  Lacquer Art - Dyeing System Manager
//

import SwiftUI
import Combine

/// Dyeing Mode
enum DyeingMode {
    case gradient    // Gradient dyeing
    case dotting     // Dot painting
    case gilding     // Gold lining
}

/// Dyeing Manager
class DyeingManager: ObservableObject {
    @Published var currentMode: DyeingMode = .gradient
    @Published var selectedColor: Color = AppColors.dyeVermillion
    @Published var brushSize: CGFloat = 15.0

    // Available colors
    let availableColors: [Color] = [
        AppColors.dyeVermillion,
        AppColors.dyeGold,
        AppColors.dyeJadeGreen,
        AppColors.dyeSapphireBlue,
        AppColors.dyeInkBlack
    ]

    /// Blend two colors
    func blendColors(_ color1: Color, _ color2: Color, ratio: Double) -> Color {
        let uiColor1 = UIColor(color1)
        let uiColor2 = UIColor(color2)

        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        uiColor1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        uiColor2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let r = r1 * (1 - ratio) + r2 * ratio
        let g = g1 * (1 - ratio) + g2 * ratio
        let b = b1 * (1 - ratio) + b2 * ratio
        let a = a1 * (1 - ratio) + a2 * ratio

        return Color(red: Double(r), green: Double(g), blue: Double(b), opacity: Double(a))
    }

    /// Calculate gradient color based on distance
    func gradientColor(from startColor: Color, to endColor: Color, distance: CGFloat, maxDistance: CGFloat) -> Color {
        let ratio = min(1.0, Double(distance / maxDistance))
        return blendColors(startColor, endColor, ratio: ratio)
    }

    /// Get brush width based on mode
    func getBrushWidth(for mode: DyeingMode) -> CGFloat {
        switch mode {
        case .gradient:
            return 20.0
        case .dotting:
            return 8.0
        case .gilding:
            return 3.0
        }
    }
}
