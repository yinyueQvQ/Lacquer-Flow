//
//  DecorationView.swift
//  Lacquer Art - Level 3: Myriad Patterns · Complete Fan
//

import SwiftUI

struct DecorationView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var gestureManager = GestureManager()
    @State private var carvingPaths: [DyeingPath] = []
    @State private var currentPath: [CGPoint] = []
    @State private var showInstructions = true
    @State private var rotationAngle: Double = 0
    @State private var carvingParticles: [CarvingParticle] = []  // carving particles

    // carving particle data
    struct CarvingParticle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var offset: CGSize = .zero
        var opacity: Double = 1.0
        var scale: Double = 1.0
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // background - change to dark gray instead of pure black
                LinearGradient(
                    colors: [
                        Color(red: 0.15, green: 0.15, blue: 0.17),
                        Color(red: 0.1, green: 0.1, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                // title (fixed at top)
                VStack {
                    VStack(spacing: 10) {
                        Text("Myriad Patterns")
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.paperWhite)

                        Text("Complete Fan")
                            .font(AppFonts.subtitle())
                            .foregroundColor(AppColors.paperWhite.opacity(0.8))
                    }
                    .padding(.top, 30)

                    Spacer()
                }

                // fan surface carving area - absolutely centered
                FanCarvingCanvas(
                    carvingPaths: $carvingPaths,
                    currentPath: $currentPath,
                    onCarving: handleCarving
                )
                .frame(width: 350, height: 350)
                .position(
                    x: 400,
                    y: 900,
                )
                .rotation3DEffect(
                    .degrees(rotationAngle),
                    axis: (x: 0, y: 1, z: 0)
                )

                // bottom info (fixed at bottom)
                VStack {
                    Spacer()

                    VStack(spacing: 15) {
                        // progress
                        ProgressIndicator(
                            progress: gameState.dyeingProgress,
                            total: 1.0,
                            label: "carving progress"
                        )
                        .frame(maxWidth: 400)

                        if showInstructions {
                            Text("Slide on fan surface to carve decoration")
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.paperWhite.opacity(0.7))
                                .transition(.opacity)
                        }
                    }
                    .padding(.bottom, 30)
                }

                // poem overlay
                PoemOverlay(text: gameState.currentPoem, isVisible: gameState.showPoem)

                // completion overlay
                if gameState.showCompletionButton {
                    CompletionView(
                        title: "First Act Complete",
                        message: Poems.actOneComplete,
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
        }
        .onAppear {
            gameState.showPoem(Poems.decorationIntro, duration: 3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }

    // MARK: - Handle Carving
    private func handleCarving() {
        // calculate carving coverage (reduce difficulty, from 500 to 200)
        let totalPoints = carvingPaths.reduce(0) { $0 + $1.points.count }
        let progress = min(1.0, Double(totalPoints) / 200.0)
        gameState.updateDyeingProgress(progress)

        // encouragement hint
        if progress >= 0.3 && progress < 0.35 {
            gameState.showPoem("Patterns emerging", duration: 1.5)
        } else if progress >= 0.6 && progress < 0.65 {
            gameState.showPoem("Layers distinct", duration: 1.5)
        } else if progress >= 0.8 {
            gameState.showPoem(Poems.decorationComplete, duration: 2.5)
            // start rotation display
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                withAnimation(.linear(duration: 3.0)) {
                    rotationAngle = 360
                }
            }
        }
    }
}

// MARK: - fan surfaceCarving Canvas
struct FanCarvingCanvas: View {
    @Binding var carvingPaths: [DyeingPath]
    @Binding var currentPath: [CGPoint]
    let onCarving: () -> Void

    @State private var isDragging = false
    @State private var sparkParticles: [SparkParticle] = []  // carving spark particles

    // spark particle structure
    struct SparkParticle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGSize
        var opacity: Double = 1.0
        var scale: Double = 1.0
    }

    var body: some View {
        ZStack {
            // fan base (black)
            FanShape()
                .fill(AppColors.lacquerBlack)

            // Vermillion surface layer - bright visible vermillion
            FanShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.2, blue: 0.2),
                            Color(red: 0.85, green: 0.1, blue: 0.1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .mask {
                    ZStack {
                        // full mask
                        Rectangle()
                            .fill(Color.white)

                        // carving paths (inverted mask)
                        ForEach(carvingPaths) { path in
                            Path { p in
                                if let first = path.points.first {
                                    p.move(to: first)
                                    for point in path.points.dropFirst() {
                                        p.addLine(to: point)
                                    }
                                }
                            }
                            .stroke(Color.black, lineWidth: path.lineWidth)
                            .blendMode(.destinationOut)
                        }

                        // current path
                        if !currentPath.isEmpty {
                            Path { p in
                                p.move(to: currentPath[0])
                                for point in currentPath.dropFirst() {
                                    p.addLine(to: point)
                                }
                            }
                            .stroke(Color.black, lineWidth: AppConstants.dyeingBrushWidth)
                            .blendMode(.destinationOut)
                        }
                    }
                }

            // gloss effect - enhanced lighting
            FanShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)

            // border - clearly show fan surface area
            FanShape()
                .stroke(Color.white.opacity(0.4), lineWidth: 3)

            // carving spark particles effect
            ForEach(sparkParticles) { particle in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.yellow.opacity(0.8),
                                Color.orange.opacity(0.6),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 3
                        )
                    )
                    .frame(width: 6, height: 6)
                    .scaleEffect(particle.scale)
                    .opacity(particle.opacity)
                    .position(particle.position)
                    .offset(particle.velocity)
            }
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
                        currentPath.append(value.location)

                        // generate carving spark particles (every few points)
                        if currentPath.count % 3 == 0 {
                            createSparkParticles(at: value.location)
                        }
                    }
                    AudioManager.shared.playHaptic(.light)
                }
                .onEnded { _ in
                    if !currentPath.isEmpty {
                        carvingPaths.append(DyeingPath(
                            points: currentPath,
                            lineWidth: AppConstants.dyeingBrushWidth
                        ))
                        currentPath = []
                        onCarving()
                    }
                    isDragging = false
                }
        )
    }

    // MARK: - Generate spark particles
    private func createSparkParticles(at position: CGPoint) {
        // generate 2-4 random direction spark particles
        let particleCount = Int.random(in: 2...4)
        for _ in 0..<particleCount {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let speed = CGFloat.random(in: 10...25)
            let velocity = CGSize(
                width: cos(angle) * speed,
                height: sin(angle) * speed
            )

            let particle = SparkParticle(
                position: position,
                velocity: velocity
            )
            sparkParticles.append(particle)

            // particle animation
            withAnimation(.easeOut(duration: 0.4)) {
                if let index = sparkParticles.firstIndex(where: { $0.id == particle.id }) {
                    sparkParticles[index].opacity = 0
                    sparkParticles[index].scale = 0.3
                }
            }

            // remove particle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                sparkParticles.removeAll { $0.id == particle.id }
            }
        }
    }
}

// MARK: - Fan Shape
struct FanShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let center = CGPoint(x: rect.midX, y: rect.minY)  // center point at top
        let radius = rect.height * 1.2
        let spreadAngle = AppConstants.fanSpreadAngle
        let startAngle = Angle(degrees: 270 - spreadAngle / 2)  // start from top
        let endAngle = Angle(degrees: 270 + spreadAngle / 2)

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
}

#Preview {
    DecorationView()
        .environmentObject(GameState())
}
