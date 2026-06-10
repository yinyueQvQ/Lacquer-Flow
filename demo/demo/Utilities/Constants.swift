//
//  Constants.swift
//  Lacquer Art - Constants
//

import SwiftUI

/// App Constants
enum AppConstants {
    // MARK: - Game Parameters
    static let targetLacquerLayers = 5          // Target lacquer layers (quick mode: 3-5 layers)
    static let targetFanBones = 7               // Number of fan bones
    static let dyeingCompletionThreshold = 0.6  // Dyeing completion threshold (lowered for quick mode)
    static let lacquerLayerOpacity = 0.15       // Opacity increment per lacquer layer (adjusted for 5 layers)

    // MARK: - Animation Duration
    static let tapAnimationDuration: Double = 0.2
    static let dragAnimationDuration: Double = 0.3
    static let transitionDuration: Double = 0.8
    static let poemDisplayDuration: Double = 2.0
    static let completionDelay: Double = 1.0

    // MARK: - Visual Parameters
    static let fanBoneLength: CGFloat = 200
    static let fanBoneWidth: CGFloat = 10
    static let fanSpreadAngle: Double = 120
    static let dyeingBrushWidth: CGFloat = 15   // Dyeing brush width for easier operation
    static let lacquerBowlSize: CGFloat = 120

    // MARK: - Gesture Parameters
    static let minimumDragDistance: CGFloat = 5
    static let doubleTapMaxInterval: TimeInterval = 0.3
    static let longPressDuration: TimeInterval = 0.5

    // MARK: - Performance Optimization
    static let maxConcurrentAnimations = 10
    static let pathSimplificationTolerance: CGFloat = 5.0
    static let maxPathPoints = 500
}

/// Poems
enum Poems {
    // MARK: - First Act Poems
    static let lacquerIntro = "Lacquer's use began with bamboo slips"
    static let lacquerCollected = "Layer upon layer, a hundred coats applied"

    static let fanBoneIntro = "Elegant object in sleeve, opens and closes with grace"
    static let fanBoneAssembled = "Seven bones form a fan, craftsmanship revealed"

    static let decorationIntro = "Colors dance upon lacquer"
    static let decorationComplete = "Hues blend in harmony"

    // MARK: - Second Act Poems
    static let lacqueringStart = "One layer of lacquer, one layer of patience"
    static let lacqueringProgress = "Layers build the vessel, mirror-bright"

    static let dyeingStart = "Brush in hand, colors flow"
    static let dyeingProgress = "Gradients emerge, beauty unfolds"

    static let presentationStart = "Months of dedication"
    static let presentationEnd = "One fan's beauty achieved"

    // MARK: - Transition Poems
    static let actOneComplete = "Origins revealed\nCraftsmanship awaits"
    static let actTwoComplete = "Lacquer artistry\nThousand years preserved"
}

/// Color Theme
enum AppColors {
    // MARK: - Theme Colors
    static let inkBlack = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let vermillion = Color(red: 0.8, green: 0.1, blue: 0.1)
    static let goldLeaf = Color(red: 0.85, green: 0.65, blue: 0.13)
    static let paperWhite = Color(red: 0.95, green: 0.94, blue: 0.90)

    // MARK: - Material Colors
    static let lacquerBlack = Color(red: 0.08, green: 0.08, blue: 0.08)
    static let lacquerRed = Color(red: 0.75, green: 0.1, blue: 0.1)
    static let woodBrown = Color(red: 0.55, green: 0.42, blue: 0.33)
    static let bambooGreen = Color(red: 0.58, green: 0.65, blue: 0.42)

    // MARK: - Dyeing Colors (Traditional Palette)
    static let dyeVermillion = Color(red: 0.9, green: 0.2, blue: 0.15)
    static let dyeGold = Color(red: 0.95, green: 0.75, blue: 0.2)
    static let dyeJadeGreen = Color(red: 0.2, green: 0.7, blue: 0.5)
    static let dyeSapphireBlue = Color(red: 0.15, green: 0.4, blue: 0.75)
    static let dyeInkBlack = Color(red: 0.1, green: 0.1, blue: 0.12)

    // MARK: - UI Colors
    static let successGreen = Color(red: 0.3, green: 0.7, blue: 0.4)
    static let warningOrange = Color(red: 0.9, green: 0.6, blue: 0.2)
    static let accentBlue = Color(red: 0.2, green: 0.5, blue: 0.8)
}

/// Font Styles
enum AppFonts {
    static func title() -> Font {
        .system(size: 48, weight: .medium, design: .serif)
    }

    static func subtitle() -> Font {
        .system(size: 32, weight: .light, design: .serif)
    }

    static func body() -> Font {
        .system(size: 20, weight: .regular, design: .serif)
    }

    static func caption() -> Font {
        .system(size: 16, weight: .light, design: .serif)
    }

    static func poem() -> Font {
        .system(size: 36, weight: .thin, design: .serif)
    }
}