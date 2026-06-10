//
//  PresentationStepView.swift
//  Lacquer Art - Second Act Step 3: Completion (Artwork Presentation)
//

import SwiftUI

struct PresentationStepView: View {
    @EnvironmentObject var gameState: GameState
    @State private var rotationAngle: Double = 0
    @State private var showScore = false
    @State private var displayedScore = 0
    @State private var showButtons = false
    @State private var animationTasks: [DispatchWorkItem] = []
    @State private var finalScore = 0

    var body: some View {
        ZStack {
            // use light beige background from screenshot
            Color(red: 0.96, green: 0.95, blue: 0.93)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // top title - simplified display
                VStack(spacing: 8) {
                    Text("Completion")
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundColor(.black)
                    
                    Text("Lacquer Art")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(red: 0.7, green: 0.2, blue: 0.1))
                }
                .padding(.top, 50)
                .opacity(showScore ? 1 : 0)

                Spacer()

                // 3D rotating fan - move down, remove ripple effect
                FinalFanView(lacquerLayers: gameState.lacquerLayers)
                    .frame(width: 300, height: 300)
                    .rotation3DEffect(
                        .degrees(rotationAngle),
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .offset(y: 300) // move fan downward
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .onAppear {
                        // start 3D rotation animation
                        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                            rotationAngle = 360
                        }
                    }

                Spacer()

                // score display
                if showScore {
                    VStack(spacing: 20) {
                        Text("Craftsmanship Score")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)

                        Text("\(displayedScore)")
                            .font(.system(size: 64, weight: .thin, design: .serif))
                            .foregroundColor(Color(red: 0.8, green: 0.6, blue: 0.2))

                        // rating
                        HStack(spacing: 5) {
                            ForEach(0..<5, id: \.self) { i in
                                Image(systemName: i < scoreStars ? "star.fill" : "star")
                                    .font(.title2)
                                    .foregroundColor(Color(red: 0.8, green: 0.6, blue: 0.2))
                            }
                        }

                        Text(scoreComment)
                            .font(.system(size: 14))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                    }
                    .transition(.scale.combined(with: .opacity))
                    .padding(.bottom, 20)
                }

                // action buttons
                if showButtons {
                    HStack(spacing: 20) {
                        // Restart
                        Button(action: restartGame) {
                            VStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.title3)
                                Text("Restart")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.white)
                            .frame(width: 140, height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color(red: 0.7, green: 0.2, blue: 0.1))
                            )
                        }

                        // view details
                        Button(action: showDetails) {
                            VStack(spacing: 8) {
                                Image(systemName: "info.circle")
                                    .font(.title3)
                                Text("Artwork Details")
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.black)
                            .frame(width: 140, height: 70)
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.white)
                                    .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(.bottom, 40)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // bottom brown bar - consistent with screenshot
                Rectangle()
                    .fill(Color(red: 0.4, green: 0.3, blue: 0.2))
                    .frame(height: 60)
                    .ignoresSafeArea(.all, edges: .bottom)
            }
        }
        .onAppear {
            startPresentation()
        }
        .onDisappear {
            animationTasks.forEach { $0.cancel() }
            animationTasks.removeAll()
        }
    }

    // MARK: - Calculate rating stars
    private var scoreStars: Int {
        let score = finalScore
        switch score {
        case 90...100: return 5
        case 80..<90: return 4
        case 70..<80: return 3
        case 60..<70: return 2
        default: return 1
        }
    }

    // MARK: - Rating Comments
    private var scoreComment: String {
        let score = finalScore
        switch score {
        case 90...100: return "Masterful Craftsmanship · Exquisite Artistry"
        case 80..<90: return "Excellent Technique · Fine Work"
        case 70..<80: return "Dedicated Work · Improving Steadily"
        case 60..<70: return "Beginner Level · Needs More Practice"
        default: return "Continue Practice · Success Awaits"
        }
    }

    // MARK: - Start Presentation Animation
    private func startPresentation() {
        animationTasks.forEach { $0.cancel() }
        animationTasks.removeAll()

        // calculate final score
        finalScore = gameState.calculateCraftingScore()

        // delayed show rating
        let scoreTask = DispatchWorkItem { [self] in
            withAnimation(.easeInOut(duration: 0.8)) {
                self.showScore = true
            }
            self.animateScore(to: finalScore)
            AudioManager.shared.playNotificationHaptic(.success)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: scoreTask)
        animationTasks.append(scoreTask)

        // show button
        let buttonTask = DispatchWorkItem { [self] in
            withAnimation(.easeInOut(duration: 0.8)) {
                self.showButtons = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: buttonTask)
        animationTasks.append(buttonTask)
    }

    // MARK: - Score Number Animation
    private func animateScore(to target: Int) {
        let duration: Double = 1.5
        let steps = min(target, 30)
        let increment = max(1, target / max(1, steps))

        for i in 0...steps {
            let task = DispatchWorkItem { [self] in
                let currentScore = min(i * increment, target)
                withAnimation(.spring(response: 0.3)) {
                    self.displayedScore = currentScore
                }
                if i < steps {
                    AudioManager.shared.playHaptic(.light)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (duration / Double(steps)) * Double(i), execute: task)
            animationTasks.append(task)
        }
    }

    // MARK: - Restart
    private func restartGame() {
        AudioManager.shared.play(.tap)
        gameState.resetGame()
    }

    // MARK: - Show Details
    private func showDetails() {
        AudioManager.shared.play(.tap)
        // Show Artwork Details logic
    }
}

// MARK: - Final Fan View (keep as is)
struct FinalFanView: View {
    let lacquerLayers: Int

    var body: some View {
        ZStack {
            // fan base
            FanShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.1, green: 0.1, blue: 0.1),
                            Color(red: 0.05, green: 0.05, blue: 0.05)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )

            // Vermillion色表层 - 使用截图中的红色
            FanShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.8, green: 0.2, blue: 0.1),
                            Color(red: 0.7, green: 0.15, blue: 0.08)
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 200
                    )
                )
                .opacity(0.9)

            // 高gloss度效果
            FanShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(Double(lacquerLayers) / 50.0),
                            Color.clear,
                            Color.white.opacity(Double(lacquerLayers) / 100.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)

            // 边缘金边
            FanShape()
                .stroke(
                    Color(red: 0.8, green: 0.6, blue: 0.2),
                    lineWidth: 3
                )
                .opacity(0.6)
        }
        .compositingGroup()
    }
}

#Preview {
    PresentationStepView()
        .environmentObject(GameState())
}
