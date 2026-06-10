//
//  LacquerMaterial.swift
//  Lacquer Art - Material Data Model
//

import SwiftUI

/// Lacquer Types
enum LacquerType: String, Codable, CaseIterable {
    case raw        // raw lacquer
    case refined    // refined lacquer
    case black      // black lacquer
    case red        // vermillion lacquer
    case gold       // gold lacquer
    case vermillion // cinnabar lacquer
    case green      // green lacquer
    case blue       // blue lacquer
    case yellow     // yellow lacquer
    case brown      // brown lacquer

    var color: Color {
        switch self {
        case .raw: return Color(red: 0.4, green: 0.3, blue: 0.2)
        case .refined: return Color(red: 0.3, green: 0.2, blue: 0.15)
        case .black: return Color(red: 0.1, green: 0.1, blue: 0.1)
        case .red: return Color(red: 0.8, green: 0.1, blue: 0.1)
        case .gold: return Color(red: 0.85, green: 0.65, blue: 0.13)
        case .vermillion: return Color(red: 0.95, green: 0.2, blue: 0.15)
        case .green: return Color(red: 0.2, green: 0.6, blue: 0.3)
        case .blue: return Color(red: 0.15, green: 0.4, blue: 0.7)
        case .yellow: return Color(red: 0.9, green: 0.75, blue: 0.2)
        case .brown: return Color(red: 0.45, green: 0.3, blue: 0.2)
        }
    }

    var name: String {
        switch self {
        case .raw: return "raw lacquer"
        case .refined: return "refined lacquer"
        case .black: return "black lacquer"
        case .red: return "Vermillion"
        case .gold: return "gold lacquer"
        case .vermillion: return "Cinnabar"
        case .green: return "green lacquer"
        case .blue: return "blue lacquer"
        case .yellow: return "yellow lacquer"
        case .brown: return "brown lacquer"
        }
    }
}

/// Lacquer Material Properties
struct LacquerMaterial: Identifiable, Codable {
    let id = UUID()
    var type: LacquerType
    var glossiness: Double      // glossiness (0.0-1.0)
    var thickness: Double       // thickness
    var transparency: Double    // opacity (0.0-1.0)

    init(type: LacquerType, glossiness: Double = 0.3, thickness: Double = 1.0, transparency: Double = 0.95) {
        self.type = type
        self.glossiness = glossiness
        self.thickness = thickness
        self.transparency = transparency
    }

    /// Increase glossiness (increases with application count)
    mutating func increaseGlossiness(by amount: Double = 0.01) {
        glossiness = min(1.0, glossiness + amount)
    }

    /// Increase thickness
    mutating func increaseThickness(by amount: Double = 0.05) {
        thickness += amount
    }

    /// Get current material visual color (considering glossiness)
    func visualColor() -> Color {
        let baseColor = type.color
        // higher glossiness, brighter color
        return baseColor.opacity(transparency)
    }
}