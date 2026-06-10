//
//  GameState.swift
//  Lacquer Art - Game State Management
//

import Foundation
import SwiftUI
import Combine
import UIKit

/// Game Progress Stages
enum GamePhase: String, Codable {
    case mainMenu       // main menu
    case firstAct       // first act: origins
    case secondAct      // second act: craftsmanship
    case completed      // all completed
}

/// First Act Levels
enum FirstActLevel: Int, Codable, CaseIterable {
    case lacquerCollection = 1  // Level 1: River's Shore · Lacquer
    case fanBones = 2           // Level 2: Elegant Object · Fan Bones
    case decoration = 3         // Level 3: Myriad Patterns · Complete Fan

    var title: String {
        switch self {
        case .lacquerCollection: return "River's Shore"
        case .fanBones: return "Elegant Object"
        case .decoration: return "Myriad Patterns"
        }
    }

    var subtitle: String {
        switch self {
        case .lacquerCollection: return "Lacquer"
        case .fanBones: return "Fan Bones"
        case .decoration: return "Complete Fan"
        }
    }
}

/// Second Act Levels
enum SecondActLevel: Int, Codable, CaseIterable {
    case lacquering = 1    // Level 1: Lacquering
    case dyeing = 2        // Level 2: Dyeing
    case presentation = 3  // Level 3: Completion

    var title: String {
        switch self {
        case .lacquering: return "Art of Lacquering"
        case .dyeing: return "Art of Dyeing"
        case .presentation: return "Beauty of Completion"
        }
    }

    var subtitle: String {
        switch self {
        case .lacquering: return "Lacquering"
        case .dyeing: return "Dyeing"
        case .presentation: return "Completion"
        }
    }
}

/// Game State Management
class GameState: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPhase: GamePhase = .mainMenu
    @Published var firstActLevel: FirstActLevel = .lacquerCollection
    @Published var secondActLevel: SecondActLevel = .lacquering
    @Published var isLevelCompleted: Bool = false
    @Published var deviceOrientation: UIDeviceOrientation = .portrait

    // MARK: - Level Unlock Status
    @Published var unlockedFirstActLevels: Set<FirstActLevel> = [.lacquerCollection]  // all first act levels unlocked
    @Published var unlockedSecondActLevels: Set<SecondActLevel> = [.lacquering]  // second act levels unlock in sequence

    // MARK: - Game Data
    @Published var lacquerLayers: Int = 0           // lacquer layer count
    @Published var lacquerLayerColors: [LacquerType] = []  // color of each lacquer layer
    @Published var collectedLacquer: Double = 0.0   // collected lacquer amount
    @Published var fanBonesAssembled: Int = 0       // assembled fan bone count
    @Published var dyeingProgress: Double = 0.0     // dyeing progress
    @Published var craftingScore: Int = 0           // craftsmanship completion score

    // MARK: - UI State
    @Published var showPoem: Bool = false           // Show poem
    @Published var currentPoem: String = ""         // current poem content
    @Published var enableInteraction: Bool = true   // interaction enabled
    @Published var showCompletionButton: Bool = false  // show completion button

    // MARK: - Game Progress
    var hasProgress: Bool {
        return currentPhase != .mainMenu || firstActLevel != .lacquerCollection
    }

    // MARK: - Initialization
    init() {
        // listen for device orientation changes
        NotificationCenter.default.addObserver(
            forName: UIDevice.orientationDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.deviceOrientation = UIDevice.current.orientation
        }
    }

    // MARK: - Game Progress Control

    /// Complete current level
    func completeCurrentLevel() {
        isLevelCompleted = true

        // Unlock next level
        unlockNextLevel()

        // show completion button instead of auto-advancing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            withAnimation(.easeInOut(duration: 0.5)) {
                self?.showCompletionButton = true
            }
        }
    }

    /// Unlock next level
    private func unlockNextLevel() {
        switch currentPhase {
        case .firstAct:
            // if first act final level completed, unlock second act first level
            if firstActLevel == .decoration {
                unlockedSecondActLevels.insert(.lacquering)
            }

        case .secondAct:
            // second act levels unlock in sequence
            if let nextLevel = SecondActLevel(rawValue: secondActLevel.rawValue + 1) {
                unlockedSecondActLevels.insert(nextLevel)
            }

        default:
            break
        }
    }

    /// user manually continues to next level
    func continueToNextLevel() {
        showCompletionButton = false
        proceedToNextLevel()
    }

    /// Enter next level
    private func proceedToNextLevel() {
        switch currentPhase {
        case .mainMenu:
            // main menu should not call this method
            break

        case .firstAct:
            if let nextLevel = FirstActLevel(rawValue: firstActLevel.rawValue + 1) {
                firstActLevel = nextLevel
                isLevelCompleted = false
                resetLevelData()
            } else {
                // first act complete, enter second act
                currentPhase = .secondAct
                secondActLevel = .lacquering
                isLevelCompleted = false
                resetLevelData()
            }

        case .secondAct:
            if let nextLevel = SecondActLevel(rawValue: secondActLevel.rawValue + 1) {
                secondActLevel = nextLevel
                isLevelCompleted = false
                resetLevelData()
            } else {
                // all completed
                currentPhase = .completed
            }

        case .completed:
            break
        }
    }

    /// Reset level data
    private func resetLevelData() {
        collectedLacquer = 0.0
        fanBonesAssembled = 0
        dyeingProgress = 0.0
        lacquerLayerColors = []  // clear lacquer layer colors
    }

    /// Add lacquer layer
    func addLacquerLayer(color: LacquerType = .black) {
        lacquerLayers += 1
        lacquerLayerColors.append(color)

        // complete level when target layers reached
        if lacquerLayers >= AppConstants.targetLacquerLayers {
            completeCurrentLevel()
        }
    }

    /// Collect lacquer
    func collectLacquer(amount: Double) {
        collectedLacquer += amount

        // complete when collected 1.0
        if collectedLacquer >= 1.0 {
            collectedLacquer = 1.0
        }
    }

    /// Assemble fan bone
    func assembleFanBone() {
        fanBonesAssembled += 1
        // don't auto-complete level, wait for user to click fold button
    }

    /// Update dyeing progress
    func updateDyeingProgress(_ progress: Double) {
        dyeingProgress = min(1.0, max(0.0, progress))

        // dyeing 80% or more complete
        if dyeingProgress >= AppConstants.dyeingCompletionThreshold {
            completeCurrentLevel()
        }
    }

    /// Show poem
    func showPoem(_ text: String, duration: TimeInterval = 3.0) {
        currentPoem = text
        withAnimation(.easeInOut(duration: 0.5)) {
            showPoem = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            withAnimation(.easeInOut(duration: 0.5)) {
                self?.showPoem = false
            }
        }
    }

    /// Calculate craftsmanship score
    func calculateCraftingScore() -> Int {
        var score = 0

        // lacquer layer score (max 40 points)
        score += min(40, lacquerLayers * 4)

        // dyeing precision score (max 60 points)
        score += Int(dyeingProgress * 60)

        craftingScore = score
        return score
    }

    /// Reset game
    func resetGame() {
        currentPhase = .mainMenu
        firstActLevel = .lacquerCollection
        secondActLevel = .lacquering
        isLevelCompleted = false
        lacquerLayers = 0
        lacquerLayerColors = []  // clear lacquer layer colors
        collectedLacquer = 0.0
        fanBonesAssembled = 0
        dyeingProgress = 0.0
        craftingScore = 0
        unlockedFirstActLevels = [.lacquerCollection]
        unlockedSecondActLevels = [.lacquering]
    }

    /// Start game
    func startGame() {
        currentPhase = .firstAct
    }

    /// Return to main menu
    func returnToMenu() {
        currentPhase = .mainMenu
        showCompletionButton = false
        showPoem = false
    }
}