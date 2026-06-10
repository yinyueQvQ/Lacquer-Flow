//
//  LacquerCollectionView.swift
//  Lacquer Art - Level 1: River's Shore · Lacquer
//

import SwiftUI

struct LacquerCollectionView: View {
    @EnvironmentObject var gameState: GameState
    @State private var treeAnimating = false
    @State private var droplets: [DropletData] = []
    @State private var lacquerInBowl: Double = 0.0
    @State private var tapCount = 0
    @State private var showInstructions = true

    // droplet data
    struct DropletData: Identifiable {
        let id = UUID()
        let slotIndex: Int  // which cut mark to flow from (0, 1, 2)
        var progress: Double = 0.0
        var opacity: Double = 1.0
        var scale: Double = 1.0
    }

    var body: some View {
        ZStack {
            // background
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.5, blue: 0.4),
                    Color(red: 0.3, green: 0.4, blue: 0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // top title
            VStack {
                VStack(spacing: 10) {
                    Text("River's Shore")
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.paperWhite)

                    Text("Lacquer")
                        .font(AppFonts.subtitle())
                        .foregroundColor(AppColors.paperWhite.opacity(0.8))
                }
                .padding(.top, 40)
                .opacity(showInstructions ? 1 : 0.3)

                Spacer()
            }

            // lacquer tree (offset left)
            LacquerTreeView(
                isAnimating: $treeAnimating,
                onTap: handleTreeTap
            )
            .position(x: 320, y: 600)

            // lacquer bowl (move left, align with droplets)
            LacquerBowlView(lacquerAmount: lacquerInBowl)
                .position(x: 360, y: 900)

            // bottom progress (fixed at bottom)
            VStack {
                Spacer()

                VStack(spacing: 20) {
                    ProgressIndicator(
                        progress: Double(gameState.lacquerLayers),
                        total: Double(AppConstants.targetLacquerLayers),
                        label: "Lacquer Layers"
                    )
                    .frame(maxWidth: 400)

                    if showInstructions {
                        Text("Tap lacquer tree to collect lacquer")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.paperWhite.opacity(0.7))
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 40)
            }

            // droplet animation
            ForEach(droplets) { droplet in
                LacquerDropletView(droplet: droplet)
            }

            // poem overlay
            PoemOverlay(text: gameState.currentPoem, isVisible: gameState.showPoem)

            // completion overlay
            if gameState.showCompletionButton {
                CompletionView(
                    title: "Level Complete",
                    message: Poems.lacquerCollected,
                    score: nil,
                    onContinue: {
                        AudioManager.shared.play(.tap)
                        AudioManager.shared.playHaptic(.medium)
                        gameState.continueToNextLevel()
                    }
                )
                .transition(.opacity)
                .zIndex(1000)
            }
        }
        .onAppear {
            gameState.showPoem(Poems.lacquerIntro, duration: 3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }

    // MARK: - Handle lacquer tree tap
    private func handleTreeTap(at location: CGPoint) {
        // if already completed, no longer respond to taps
        guard !gameState.isLevelCompleted else { return }

        // if target layers reached, no longer respond to taps
        guard gameState.lacquerLayers < AppConstants.targetLacquerLayers else { return }

        // play sound effect
        AudioManager.shared.play(.tap)
        AudioManager.shared.playHaptic(.light)

        // tree animation - enhanced shaking effect
        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
            treeAnimating = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                treeAnimating = false
            }
        }

        // Create 1 droplet from middle cut mark
        let droplet = DropletData(slotIndex: 1)
        droplets.append(droplet)

        // Droplet falling animation - vertical fall
        withAnimation(.spring(response: 1.0, dampingFraction: 0.8)) {
            if let index = droplets.firstIndex(where: { $0.id == droplet.id }) {
                droplets[index].progress = 1.0
            }
        }

        // Droplet fade effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                if let index = droplets.firstIndex(where: { $0.id == droplet.id }) {
                    droplets[index].opacity = 0.0
                    droplets[index].scale = 0.5
                }
            }
        }

        // Droplet reaches bowl
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                lacquerInBowl += 0.02
            }
            tapCount += 1

            // Delayed removal of droplet
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                droplets.removeAll { $0.id == droplet.id }
            }
        }

            // Collect enough for one layer (reduced to 3 taps)
            if tapCount >= 3 {
                AudioManager.shared.play(.lacquer)
                gameState.addLacquerLayer()
                lacquerInBowl = 0.0
                tapCount = 0

                // Show encouragement
                if gameState.lacquerLayers == 3 {
                    gameState.showPoem("Layers taking shape", duration: 1.5)
                } else if gameState.lacquerLayers == 5 {
                    gameState.showPoem("Mirror-bright finish", duration: 1.5)
                }
            }
        }
    }


// MARK: - Lacquer Tree View
struct LacquerTreeView: View {
    @Binding var isAnimating: Bool
    let onTap: (CGPoint) -> Void

    var body: some View {
        ZStack {
            // tree trunk - larger and thicker
            RoundedRectangle(cornerRadius: 25)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.25, blue: 0.2),
                            Color(red: 0.4, green: 0.35, blue: 0.3),
                            Color(red: 0.35, green: 0.3, blue: 0.25)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80, height: 350)
                .offset(x: isAnimating ? -4 : 4)
                .rotation3DEffect(
                    .degrees(isAnimating ? -2 : 2),
                    axis: (x: 0, y: 1, z: 0)
                )

            // cut marks (collection points) - show all three cut marks
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(Color(red: 0.5, green: 0.4, blue: 0.3))
                    .frame(width: 50, height: 5)
                    .offset(y: CGFloat(i - 1) * 80)
                    .overlay(
                        Capsule()
                            .fill(Color(red: 0.6, green: 0.5, blue: 0.4).opacity(isAnimating && i == 1 ? 0.6 : 0))
                            .blur(radius: 2)
                    )
            }

            // lacquer liquid flowing effect - only show middle cut mark animation
            if isAnimating {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 0.45, green: 0.35, blue: 0.25),
                                Color(red: 0.35, green: 0.25, blue: 0.18)
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: 5
                        )
                    )
                    .frame(width: 12, height: 12)
                    .offset(x: 28, y: 0)  // middle position
                    .scaleEffect(isAnimating ? 1.3 : 0.5)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { location in
            onTap(location)
        }
    }
}

// MARK: - Lacquer Bowl View
struct LacquerBowlView: View {
    let lacquerAmount: Double

    var body: some View {
        ZStack {
            // bowl (top-down view, flat ellipse)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.5, green: 0.4, blue: 0.35),
                            Color(red: 0.3, green: 0.25, blue: 0.2)
                        ],
                        center: .center,
                        startRadius: 30,
                        endRadius: 80
                    )
                )
                .frame(width: 140, height: 60)  // flat ellipse
                .overlay(
                    Ellipse()
                        .stroke(Color.black.opacity(0.3), lineWidth: 3)
                )

            // lacquer liquid in bowl
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.3, green: 0.2, blue: 0.15),
                            Color(red: 0.2, green: 0.15, blue: 0.1)
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 50
                    )
                )
                .frame(width: 120 * (0.5 + lacquerAmount * 0.5), height: 40 * (0.5 + lacquerAmount * 0.5))
                .animation(.lightSpring, value: lacquerAmount)

            // gloss
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 20)
                .offset(x: -25, y: -8)
                .blendMode(.overlay)
        }
    }
}

// MARK: - Droplet View
struct LacquerDropletView: View {
    let droplet: LacquerCollectionView.DropletData

    // Calculate droplet Y position (avoid compile type check timeout)
    private var dropletY: CGFloat {
        let treeY: CGFloat = 600
        let startY = treeY  // start from tree center (middle cut mark position)
        let fallDistance: CGFloat = 300  // fall distance to reach bowl
        let currentY = startY + (fallDistance * CGFloat(droplet.progress))
        return currentY
    }

    var body: some View {
        ZStack {
            // droplet body - droplet shape
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.45, green: 0.35, blue: 0.25),
                            Color(red: 0.35, green: 0.25, blue: 0.18)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 8
                    )
                )
                .frame(width: 12, height: 16)

            // highlight effect
            Circle()
                .fill(Color.white.opacity(0.4))
                .frame(width: 4, height: 4)
                .offset(x: -2, y: -3)

            // trail effect (motion blur) - enhanced trail
            if droplet.progress > 0.1 {
                Ellipse()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.3, blue: 0.2).opacity(0.4 * droplet.opacity),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 10, height: 25)
                    .offset(y: -15)
                    .opacity(droplet.progress * 0.7)
            }
        }
        .scaleEffect(droplet.scale)
        .opacity(droplet.opacity)
        .position(x: 360, y: dropletY)  // flow from right side of tree (tree at x:320, width 80, right side at x:360)
        .shadow(color: .black.opacity(0.2 * droplet.opacity), radius: 3, x: 0, y: 2)
    }
}

#Preview {
    LacquerCollectionView()
        .environmentObject(GameState())
}
