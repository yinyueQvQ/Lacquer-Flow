//
//  DyeingStepView.swift
//  Lacquer Art - Second Act Step 2: Dyeing
//

import SwiftUI

struct DyeingStepView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var dyeingManager = DyeingManager()
    @State private var dyeingPaths: [DyeingPath] = []
    @State private var currentPath: [CGPoint] = []
    @State private var showInstructions = true
    @State private var showGuidePattern = false

    var body: some View {
        ZStack {
            // dark background
            Color(red: 0.08, green: 0.08, blue: 0.1)
                .ignoresSafeArea()

            // top title (fixed at top)
            VStack {
                VStack(spacing: 10) {
                    Text("Decoration")
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.paperWhite)

                    Text("Dyeing")
                        .font(AppFonts.subtitle())
                        .foregroundColor(AppColors.paperWhite.opacity(0.8))
                }
                .padding(.top, 40)

                Spacer()
            }

            // dyeing canvas - absolutely centered
            ZStack {
                // dyeing area
                DyeingCanvas(
                    dyeingPaths: $dyeingPaths,
                    currentPath: $currentPath,
                    lacquerLayers: gameState.lacquerLayers,
                    lacquerLayerColors: gameState.lacquerLayerColors,
                    selectedColor: dyeingManager.selectedColor
                )
                .frame(width: 350, height: 350)
            }
            .position(
                x: 400,
                y: 900
            )

            // bottom info (fixed at bottom)
            VStack {
                Spacer()

                VStack(spacing: 20) {
                    // Color picker
                    DyeingColorPicker(dyeingManager: dyeingManager)
                        .frame(height: 80)

                    // progress
                    ProgressIndicator(
                        progress: gameState.dyeingProgress,
                        total: 1.0,
                        label: "dyeing progress"
                    )
                    .frame(maxWidth: 400)

                    // control buttons
                    HStack(spacing: 30) {
                        // toggle reference pattern
                        Button(action: {
                            withAnimation {
                                showGuidePattern.toggle()
                            }
                        }) {
                            HStack {
                                Image(systemName: showGuidePattern ? "eye.fill" : "eye.slash.fill")
                                Text(showGuidePattern ? "Hide" : "Show")
                            }
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.paperWhite)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }

                        // clear button
                        Button(action: clearLastPath) {
                            HStack {
                                Image(systemName: "arrow.uturn.backward")
                                Text("undo")
                            }
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.paperWhite)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.2))
                            )
                        }
                        .disabled(dyeingPaths.isEmpty)
                        .opacity(dyeingPaths.isEmpty ? 0.5 : 1.0)
                    }

                    if showInstructions {
                        Text("Slide finger on fan surface to dye decoration")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.paperWhite.opacity(0.7))
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
                    message: Poems.dyeingProgress,
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
        .onChange(of: dyeingPaths.count) { _ in
            updateProgress()
        }
        .onAppear {
            gameState.showPoem(Poems.dyeingStart, duration: 3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }

    // MARK: - Update dyeing progress
    private func updateProgress() {
        let totalPoints = dyeingPaths.reduce(0) { $0 + $1.points.count }
        let progress = min(1.0, Double(totalPoints) / 500.0)
        gameState.updateDyeingProgress(progress)

        // encouragement hint
        if progress >= 0.25 && progress < 0.3 {
            gameState.showPoem("First Dyeing Marks", duration: 1.5)
        } else if progress >= 0.5 && progress < 0.55 {
            gameState.showPoem(Poems.dyeingProgress, duration: 1.5)
        } else if progress >= 0.75 && progress < 0.8 {
            gameState.showPoem("Nearly Perfect", duration: 1.5)
        }
    }

    // MARK: - Clear Last Stroke
    private func clearLastPath() {
        guard !dyeingPaths.isEmpty else { return }
        AudioManager.shared.play(.tap)
        withAnimation {
            dyeingPaths.removeLast()
        }
        updateProgress()
    }
}

// MARK: - Dyeing Canvas (with multiple lacquer layers)
struct DyeingCanvas: View {
    @Binding var dyeingPaths: [DyeingPath]
    @Binding var currentPath: [CGPoint]
    let lacquerLayers: Int
    let lacquerLayerColors: [LacquerType]
    let selectedColor: Color

    @State private var isDragging = false

    var body: some View {
        ZStack {
            // fan base (wooden bottom layer)
            FanShape()
                .fill(
                    RadialGradient(
                        colors: [
                            AppColors.woodBrown,
                            AppColors.woodBrown.opacity(0.85)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )

            // show color of each lacquer layer (overlay from bottom to top)
            ForEach(Array(lacquerLayerColors.enumerated()), id: \.offset) { index, lacquerColor in
                FanShape()
                    .fill(
                        RadialGradient(
                            colors: [
                                lacquerColor.color.opacity(0.75),
                                lacquerColor.color.opacity(0.65)
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .opacity(0.35 + Double(index) * 0.05)  // opacity increases per layer
            }

            // Dyeing paths overlay
            Canvas { context, size in
                for dyeingPath in dyeingPaths {
                    var path = Path()
                    if let first = dyeingPath.points.first {
                        path.move(to: first)
                        for point in dyeingPath.points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                    context.stroke(
                        path,
                        with: .color(dyeingPath.color),
                        style: StrokeStyle(lineWidth: dyeingPath.lineWidth, lineCap: .round, lineJoin: .round)
                    )
                }

                // current path
                if !currentPath.isEmpty {
                    var path = Path()
                    path.move(to: currentPath[0])
                    for point in currentPath.dropFirst() {
                        path.addLine(to: point)
                    }
                    context.stroke(
                        path,
                        with: .color(selectedColor),
                        style: StrokeStyle(lineWidth: AppConstants.dyeingBrushWidth, lineCap: .round, lineJoin: .round)
                    )
                }
            }
            .mask(FanShape())

            // Overall gloss layer (increases with lacquer layers)
            FanShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(Double(lacquerLayers) / 100.0),
                            Color.clear,
                            Color.white.opacity(Double(lacquerLayers) / 150.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
        }
        .compositingGroup()
        .contentShape(FanShape())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging {
                        isDragging = true
                        currentPath = [value.location]
                        AudioManager.shared.play(.carve)
                    } else {
                        // Optimization: only record after moving a certain distance
                        if let last = currentPath.last {
                            let distance = hypot(
                                value.location.x - last.x,
                                value.location.y - last.y
                            )
                            if distance >= AppConstants.minimumDragDistance {
                                currentPath.append(value.location)
                            }
                        }
                    }
                    AudioManager.shared.playHaptic(.light)
                }
                .onEnded { _ in
                    if currentPath.count > 1 {
                        dyeingPaths.append(DyeingPath(
                            points: currentPath,
                            color: selectedColor,
                            lineWidth: AppConstants.dyeingBrushWidth
                        ))
                        AudioManager.shared.playNotificationHaptic(.success)
                    }
                    currentPath = []
                    isDragging = false
                }
        )
    }
}

// MARK: - Dyeing Color Picker
struct DyeingColorPicker: View {
    @ObservedObject var dyeingManager: DyeingManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(dyeingManager.availableColors, id: \.self) { color in
                    Circle()
                        .fill(color)
                        .frame(width: 50, height: 50)
                        .overlay(
                            Circle()
                                .stroke(
                                    dyeingManager.selectedColor == color ? AppColors.goldLeaf : Color.clear,
                                    lineWidth: 3
                                )
                        )
                        .shadow(
                            color: dyeingManager.selectedColor == color ? color.opacity(0.5) : .clear,
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                AudioManager.shared.play(.tap)
                                AudioManager.shared.playHaptic(.light)
                                dyeingManager.selectedColor = color
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Reference Pattern View
struct GuidePatternView: View {
    var body: some View {
        ZStack {
            FanShape()
                .stroke(Color.white.opacity(0.3), lineWidth: 1)

            // Simple cloud pattern
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height)

                // Draw several arcs as reference
                for i in 0..<3 {
                    let radius = 80.0 + Double(i) * 40.0
                    let angle = Double(i - 1) * 30.0

                    var path = Path()
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(angle - 20),
                        endAngle: .degrees(angle + 20),
                        clockwise: false
                    )

                    context.stroke(
                        path,
                        with: .color(.white),
                        lineWidth: 2
                    )
                }
            }
        }
    }
}

#Preview {
    DyeingStepView()
        .environmentObject(GameState())
}