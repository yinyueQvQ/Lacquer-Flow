//
//  LevelMenuView.swift
//  Lacquer Art - Level Menu
//

import SwiftUI

struct LevelMenuView: View {
    @EnvironmentObject var gameState: GameState
    @Binding var isPresented: Bool
    @Binding var showFreeCreation: Bool  // controlled by parent view

    var body: some View {
        ZStack {
            // semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation {
                        isPresented = false
                    }
                }

            // menu panel
            VStack(spacing: 30) {
                // title
                HStack {
                    Text("Level Directory")
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.inkBlack)

                    Spacer()

                    // close button
                    Button(action: {
                        withAnimation {
                            isPresented = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(AppColors.inkBlack.opacity(0.6))
                    }
                }

                ScrollView {
                    VStack(spacing: 20) {
                        // First Act Levels
                        VStack(alignment: .leading, spacing: 15) {
                            Text("first act: origins")
                                .font(AppFonts.subtitle())
                                .foregroundColor(AppColors.vermillion)

                            ForEach(FirstActLevel.allCases, id: \.self) { level in
                                LevelButton(
                                    title: level.title,
                                    subtitle: level.subtitle,
                                    isUnlocked: isLevelUnlocked(level),
                                    isCurrent: gameState.currentPhase == .firstAct && gameState.firstActLevel == level
                                ) {
                                    jumpToLevel(level)
                                }
                            }
                        }

                        Divider()
                            .background(AppColors.inkBlack.opacity(0.2))

                        // Second Act
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Second Act: Craftsmanship")
                                .font(AppFonts.subtitle())
                                .foregroundColor(AppColors.vermillion)

                            ForEach(SecondActLevel.allCases, id: \.self) { level in
                                LevelButton(
                                    title: level.title,
                                    subtitle: level.subtitle,
                                    isUnlocked: isSecondActLevelUnlocked(level),
                                    isCurrent: gameState.currentPhase == .secondAct && gameState.secondActLevel == level
                                ) {
                                    jumpToSecondActLevel(level)
                                }
                            }
                        }
                    }
                    .padding(.vertical)
                }

                // bottom action buttons
                VStack(spacing: 16) {
                    // Free Creation button (gold, most prominent)
                    Button(action: {
                        AudioManager.shared.play(.tap)
                        AudioManager.shared.playHaptic(.medium)
                        isPresented = false
                        // delayed trigger, ensure menu closes first
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showFreeCreation = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "paintpalette.fill")
                                .font(.title2)
                            Text("Free Creation")
                                .font(AppFonts.body())
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(AppColors.paperWhite)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppColors.goldLeaf,
                                            AppColors.goldLeaf.opacity(0.85)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .shadow(color: AppColors.goldLeaf.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                    }

                    HStack(spacing: 16) {
                        // back button
                        if canGoBack() {
                            Button(action: goBack) {
                                HStack {
                                    Image(systemName: "arrow.left")
                                    Text("Back")
                                }
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.paperWhite)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(AppColors.inkBlack)
                                )
                            }
                        }

                        // Restart
                        Button(action: restartCurrentLevel) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Restart")
                            }
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.paperWhite)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(AppColors.vermillion)
                            )
                        }

                        // back to home
                        Button(action: {
                            AudioManager.shared.play(.tap)
                            AudioManager.shared.playHaptic(.light)
                            withAnimation {
                                gameState.currentPhase = .mainMenu
                                isPresented = false
                            }
                        }) {
                            HStack {
                                Image(systemName: "house.fill")
                                Text("Home")
                            }
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.inkBlack)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(AppColors.paperWhite)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 15)
                                            .stroke(AppColors.inkBlack.opacity(0.08), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 30)
                    .fill(AppColors.paperWhite)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(40)
        }
    }

    // MARK: - Level unlock check

    private func isLevelUnlocked(_ level: FirstActLevel) -> Bool {
        // all first act levels are unlocked
        return true
    }

    private func isSecondActLevelUnlocked(_ level: SecondActLevel) -> Bool {
        // check if in unlocked list
        return gameState.unlockedSecondActLevels.contains(level)
    }

    // MARK: - Jump functionality

    private func jumpToLevel(_ level: FirstActLevel) {
        guard isLevelUnlocked(level) else {
            AudioManager.shared.play(.tap)
            return
        }

        AudioManager.shared.play(.success)
        gameState.currentPhase = .firstAct
        gameState.firstActLevel = level
        gameState.isLevelCompleted = false
        withAnimation {
            isPresented = false
        }
    }

    private func jumpToSecondActLevel(_ level: SecondActLevel) {
        guard isSecondActLevelUnlocked(level) else {
            AudioManager.shared.play(.tap)
            return
        }

        AudioManager.shared.play(.success)
        gameState.currentPhase = .secondAct
        gameState.secondActLevel = level
        gameState.isLevelCompleted = false
        withAnimation {
            isPresented = false
        }
    }

    // MARK: - Back functionality

    private func canGoBack() -> Bool {
        if gameState.currentPhase == .firstAct {
            return gameState.firstActLevel != .lacquerCollection
        } else if gameState.currentPhase == .secondAct {
            return gameState.secondActLevel != .lacquering
        }
        return false
    }

    private func goBack() {
        AudioManager.shared.play(.tap)

        if gameState.currentPhase == .secondAct {
            // go back to previous level
            if let currentIndex = SecondActLevel.allCases.firstIndex(of: gameState.secondActLevel),
               currentIndex > 0 {
                gameState.secondActLevel = SecondActLevel.allCases[currentIndex - 1]
            }
        } else if gameState.currentPhase == .firstAct {
            // go back to previous level
            if let currentIndex = FirstActLevel.allCases.firstIndex(of: gameState.firstActLevel),
               currentIndex > 0 {
                gameState.firstActLevel = FirstActLevel.allCases[currentIndex - 1]
            }
        }

        gameState.isLevelCompleted = false
        withAnimation {
            isPresented = false
        }
    }

    // MARK: - Restart

    private func restartCurrentLevel() {
        AudioManager.shared.play(.tap)

        // reset current level data
        gameState.lacquerLayers = 0
        gameState.collectedLacquer = 0.0
        gameState.fanBonesAssembled = 0
        gameState.dyeingProgress = 0.0
        gameState.isLevelCompleted = false

        withAnimation {
            isPresented = false
        }
    }
}

// MARK: - Level button component
struct LevelButton: View {
    let title: String
    let subtitle: String
    let isUnlocked: Bool
    let isCurrent: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(AppFonts.body())
                        .foregroundColor(isUnlocked ? AppColors.inkBlack : AppColors.inkBlack.opacity(0.3))

                    Text(subtitle)
                        .font(AppFonts.caption())
                        .foregroundColor(isUnlocked ? AppColors.inkBlack.opacity(0.6) : AppColors.inkBlack.opacity(0.2))
                }

                Spacer()

                if isCurrent {
                    Image(systemName: "play.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppColors.vermillion)
                } else if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.title3)
                        .foregroundColor(AppColors.inkBlack.opacity(0.3))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.title3)
                        .foregroundColor(AppColors.inkBlack.opacity(0.4))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isCurrent ? AppColors.vermillion.opacity(0.1) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(
                                isCurrent ? AppColors.vermillion : AppColors.inkBlack.opacity(0.1),
                                lineWidth: isCurrent ? 2 : 1
                            )
                    )
            )
        }
        .disabled(!isUnlocked)
    }
}

#Preview {
    LevelMenuView(isPresented: .constant(true), showFreeCreation: .constant(false))
        .environmentObject(GameState())
}