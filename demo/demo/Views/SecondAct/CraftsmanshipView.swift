//
//  CraftsmanshipView.swift
//  Lacquer Art - Second Act: Craftsmanship (Lacquering, Carving, Completion)
//

import SwiftUI

// MARK: - Step 1: Lacquering
struct LacqueringStepView: View {
    @EnvironmentObject var gameState: GameState
    @State private var lacquerBowlPosition = CGPoint(x: 200, y: 600)
    @State private var isDraggingBrush = false
    @State private var brushPosition = CGPoint(x: 200, y: 700)
    @State private var haslacquer = false
    @State private var selectedColor: LacquerType = .black  // currently selected color
    @State private var opacity: Double = 0.0
    @State private var showInstructions = true
    @State private var showColorPicker = false  // show color selection
    @State private var hasShownPickupPoem = false  // whether lacquer pickup hint has been shown

    var body: some View {
        ZStack {
            // background
            RenderManager.shared.studioDeskBackground()

            // top title (fixed at top)
            VStack {
                VStack(spacing: 10) {
                    Text("Lacquering")
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.inkBlack)

                    Text("Layered Experience")
                        .font(AppFonts.subtitle())
                        .foregroundColor(AppColors.inkBlack.opacity(0.7))
                }
                .padding(.top, 40)

                Spacer()
            }

            // fan surface (lacquering area) - absolutely centered, show multiple lacquer layers
            ZStack {
                // base fan shape
                FanShape()
                    .fill(AppColors.woodBrown)
                    .frame(width: 350, height: 350)

                // show color of each lacquer layer (overlay effect)
                ForEach(Array(gameState.lacquerLayerColors.enumerated()), id: \.offset) { index, color in
                    FanShape()
                        .fill(
                            RadialGradient(
                                colors: [
                                    color.color.opacity(0.7),
                                    color.color.opacity(0.6)
                                ],
                                center: .center,
                                startRadius: 50,
                                endRadius: 200
                            )
                        )
                        .frame(width: 350, height: 350)
                        .opacity(0.3 + Double(index) * 0.05)  // opacity increases per layer
                }

                // gloss effect (enhanced based on lacquer layer count)
                FanShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(Double(gameState.lacquerLayers) * 0.04),
                                Color.clear,
                                Color.white.opacity(Double(gameState.lacquerLayers) * 0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 350, height: 350)
                    .blendMode(.overlay)

                // border
                FanShape()
                    .stroke(AppColors.goldLeaf.opacity(showInstructions ? 0.5 : 0.3), lineWidth: 3)
                    .frame(width: 350, height: 350)
            }
            .contentShape(FanShape())
            .onTapGesture {
                if haslacquer {
                    applyLacquer()
                }
            }
            .position(
                x: 400,
                y: 600
            )

            // bottom info (fixed at bottom)
            VStack {
                Spacer()

                VStack(spacing: 20) {
                    // color selection
                    ColorPickerView(
                        selectedColor: $selectedColor,
                        onColorSelected: { color in
                            selectedColor = color
                        }
                    )
                    .frame(height: 80)

                    // lacquer bowl and brush
                    HStack(spacing: 80) {
                        // lacquer bowl (show currently selected color)
                        VStack {
                            ZStack {
                                Circle()
                                    .fill(
                                        RenderManager.shared.lacquerBowlGradient(for: selectedColor)
                                    )
                                    .frame(width: AppConstants.lacquerBowlSize, height: AppConstants.lacquerBowlSize)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.black.opacity(0.3), lineWidth: 3)
                                    )

                                // gloss
                                Circle()
                                    .fill(
                                        RadialGradient(
                                            colors: [Color.white.opacity(0.3), Color.clear],
                                            center: .topLeading,
                                            startRadius: 10,
                                            endRadius: 60
                                        )
                                    )
                                    .frame(width: 80, height: 80)
                                    .offset(x: -10, y: -10)
                            }
                            .onTapGesture {
                                pickUpLacquer()
                            }

                            Text(selectedColor.name)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.inkBlack.opacity(0.7))
                        }

                        // brush indicator
                        VStack {
                            Circle()
                                .fill(haslacquer ? selectedColor.color : Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Image(systemName: "paintbrush.fill")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )

                            Text(haslacquer ? "Lacquer Picked" : "Brush")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.inkBlack.opacity(0.7))
                        }
                    }

                    // progress
                    ProgressIndicator(
                        progress: Double(gameState.lacquerLayers),
                        total: Double(AppConstants.targetLacquerLayers),
                        label: "Lacquer Layers"
                    )
                    .frame(maxWidth: 400)

                    if showInstructions {
                        Text("Select color, tap lacquer bowl to pick up, tap fan surface to apply lacquer")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.inkBlack.opacity(0.7))
                            .transition(.opacity)
                    }
                }
                .padding(.bottom, 40)
            }

            // poem overlay
            PoemOverlay(text: gameState.currentPoem, isVisible: gameState.showPoem)

            // completion overlay
            if gameState.showCompletionButton {
                CompletionView(
                    title: "Step Complete",
                    message: Poems.lacqueringProgress,
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
            // reset lacquer pickup hint state
            hasShownPickupPoem = false
            gameState.showPoem(Poems.lacqueringStart, duration: 3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }

    // MARK: - Pick Up Lacquer Liquid
    private func pickUpLacquer() {
        AudioManager.shared.play(.lacquer)
        AudioManager.shared.playHaptic(UIImpactFeedbackGenerator.FeedbackStyle.light)

        withAnimation(.quickEase) {
            haslacquer = true
        }

        // only show hint on first lacquer pickup
        if !hasShownPickupPoem {
            gameState.showPoem("Lacquer on Brush", duration: 1.0)
            hasShownPickupPoem = true
        }
    }

    // MARK: - Apply Lacquer
    private func applyLacquer() {
        guard haslacquer else { return }

        AudioManager.shared.play(.tap)
        AudioManager.shared.playHaptic(UIImpactFeedbackGenerator.FeedbackStyle.medium)

        // Add lacquer layer (with color)
        gameState.addLacquerLayer(color: selectedColor)
        opacity += AppConstants.lacquerLayerOpacity

        // use up lacquer liquid
        haslacquer = false

        // encouragement hint
        if gameState.lacquerLayers == 3 {
            gameState.showPoem("Layers taking shape", duration: 2.0)
            gameState.showPoem("Nearing completion", duration: 2.0)
        }
    }
}

// MARK: - Color Selection View
struct ColorPickerView: View {
    @Binding var selectedColor: LacquerType
    let onColorSelected: (LacquerType) -> Void

    // Available colors (selected traditional lacquer colors)
    private let availableColors: [LacquerType] = [
        .black, .red, .vermillion, .gold, .green, .blue, .yellow, .brown
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(availableColors, id: \.self) { color in
                    VStack(spacing: 5) {
                        Circle()
                            .fill(
                                RenderManager.shared.lacquerBowlGradient(for: color)
                            )
                            .frame(width: 50, height: 50)
                            .overlay(
                                Circle()
                                    .stroke(
                                        selectedColor == color ? AppColors.goldLeaf : Color.clear,
                                        lineWidth: 3
                                    )
                            )
                            .shadow(
                                color: selectedColor == color ? color.color.opacity(0.4) : .clear,
                                radius: 8,
                                x: 0,
                                y: 4
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                    AudioManager.shared.play(.tap)
                                    AudioManager.shared.playHaptic(.light)
                                    onColorSelected(color)
                                }
                            }

                        Text(color.name)
                            .font(.system(size: 12, design: .serif))
                            .foregroundColor(
                                selectedColor == color ? AppColors.inkBlack : AppColors.inkBlack.opacity(0.5)
                            )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

#Preview {
    LacqueringStepView()
        .environmentObject(GameState())
}