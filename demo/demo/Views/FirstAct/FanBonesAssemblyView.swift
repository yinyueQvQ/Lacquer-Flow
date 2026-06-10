//
//  FanBonesAssemblyView.swift
//  Lacquer Art - Level 2: Elegant Object · Fan Bones
//

import SwiftUI

struct FanBonesAssemblyView: View {
    @EnvironmentObject var gameState: GameState
    @StateObject private var gestureManager = GestureManager()
    @State private var fanBones: [DraggableFanBone] = []
    @State private var assembledBones: [AssembledBone] = []
    @State private var isOpen = true
    @State private var showInstructions = true
    @State private var justAssembledIndex: Int? = nil  // just assembled fan bone index

    // draggable fan bones
    struct DraggableFanBone: Identifiable {
        let id = UUID()
        let index: Int
        var position: CGPoint = .zero
        var isDragging: Bool = false
    }

    // assembled fan bones
    struct AssembledBone: Identifiable {
        let id = UUID()
        let index: Int
        var rotation: Double
    }

    var body: some View {
        ZStack {
            // background
            RenderManager.shared.inkWashBackground()

            VStack(spacing: 40) {
                // title
                VStack(spacing: 10) {
                    Text("Elegant Object")
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.inkBlack)

                    Text("Fan Bones")
                        .font(AppFonts.subtitle())
                        .foregroundColor(AppColors.inkBlack.opacity(0.7))
                }

                Spacer()

                // fan assembly area
                GeometryReader { geometry in
                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    let containerX = geometry.size.width - 150  // lottery bucket X coordinate
                    let containerY = geometry.size.height + 50  // lottery bucket Y coordinate

                    ZStack {
                        // fan mold (placement target)
                        FanMoldView()
                            .position(x: center.x, y: center.y)

                        // assembled fan bones
                        ForEach(assembledBones) { bone in
                            FanBoneShape()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppColors.woodBrown,
                                            AppColors.woodBrown.opacity(0.8)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 12, height: AppConstants.fanBoneLength)
                                .rotationEffect(
                                    .degrees(isOpen ? bone.rotation : 0),  // ✅ remove +180 degree offset
                                                anchor: .bottom  // ✅ rotate from bottom (consistent with dashed frame)
                                )
                                .position(x: center.x, y: center.y)
                                .animation(.softSpring, value: isOpen)
                                .offset(y: -95)  // ✅ add upward offset to center bottom
                        }

                        

                        // fan bones to assemble - inserted vertically in bucket
                        ForEach(fanBones.indices, id: \.self) { index in
                            let boneSpacing: CGFloat = 20
                            let offsetX = CGFloat(index - 3) * boneSpacing

                            FanBoneShape()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppColors.woodBrown,
                                            AppColors.woodBrown.opacity(0.8)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 12, height: 100)
                                .rotationEffect(.degrees(0))  // insert vertically, fan bone tip up
                                .position(
                                    x: fanBones[index].isDragging ? fanBones[index].position.x : containerX + offsetX,
                                    y: fanBones[index].isDragging ? fanBones[index].position.y : containerY - 70  // offset upward to expose fan bones from bucket
                                )
                                .opacity(fanBones[index].isDragging ? 0.9 : 1.0)
                                .scaleEffect(fanBones[index].isDragging ? 1.15 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: fanBones[index].isDragging)
                                .shadow(
                                    color: fanBones[index].isDragging ? AppColors.goldLeaf.opacity(0.4) : .black.opacity(0.1),
                                    radius: fanBones[index].isDragging ? 15 : 2,
                                    x: 0,
                                    y: fanBones[index].isDragging ? 8 : 2
                                )
                                .gesture(
                                    DragGesture(coordinateSpace: .local)
                                        .onChanged { value in
                                            handleDragChange(index: index, value: value)
                                        }
                                        .onEnded { value in
                                            handleDragEnd(index: index, value: value, center: center)
                                        }
                                )
                        }
                        
                        // lottery bucket container (bottom right)
                        LotteryContainerView()
                            .position(x: containerX, y: containerY)
                        
                    }
                }
                .frame(height: 400)

                Spacer()

                // bottom controls
                VStack(spacing: 20) {
                    // progress
                    ProgressIndicator(
                        progress: Double(gameState.fanBonesAssembled),
                        total: Double(AppConstants.targetFanBones),
                        label: "Fan Bones"
                    )
                    .frame(maxWidth: 400)

                    // open/close button (shown after assembly complete)
                    if assembledBones.count == AppConstants.targetFanBones {
                        HStack(spacing: 40) {
                            Button(action: toggleFan) {
                                HStack {
                                    Image(systemName: isOpen ? "arrowtriangle.right.fill" : "arrowtriangle.left.fill")
                                    Text(isOpen ? "Fold" : "Open")
                                }
                                .font(AppFonts.body())
                                .foregroundColor(AppColors.paperWhite)
                                .padding(.horizontal, 30)
                                .padding(.vertical, 15)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(AppColors.vermillion)
                                )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    } else if showInstructions {
                        Text("Drag fan bones to center to assemble")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.inkBlack.opacity(0.7))
                            .transition(.opacity)
                    }
                }
            }
            .padding(40)

            // poem overlay
            PoemOverlay(text: gameState.currentPoem, isVisible: gameState.showPoem)

            // completion overlay
            if gameState.showCompletionButton {
                CompletionView(
                    title: "Level Complete",
                    message: Poems.fanBoneAssembled,
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
            // Initialize fan bone array
            for i in 0..<AppConstants.targetFanBones {
                fanBones.append(DraggableFanBone(index: i))
            }

            gameState.showPoem(Poems.fanBoneIntro, duration: 3.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }

    // MARK: - handle drag
    private func handleDragChange(index: Int, value: DragGesture.Value) {
        // use drag gesture location (in parent container coordinate system)
        fanBones[index].position = value.location
        fanBones[index].isDragging = true
    }

    private func handleDragEnd(index: Int, value: DragGesture.Value, center: CGPoint) {
        let location = value.location
        let distance = hypot(location.x - center.x, location.y - center.y)

        // check if close to center (snap distance)
        if distance < 100 {
            // assembly successful
            AudioManager.shared.play(.assemble)
            AudioManager.shared.playHaptic(.medium)

            let rotation = calculateRotation(for: assembledBones.count)
            assembledBones.append(AssembledBone(
                index: fanBones[index].index,
                rotation: rotation
            ))

            fanBones.remove(at: index)
            gameState.assembleFanBone()

            // encouragement hint
            if assembledBones.count == 3 {
                gameState.showPoem("Taking shape", duration: 1.5)
            } else if assembledBones.count == AppConstants.targetFanBones {
                gameState.showPoem(Poems.fanBoneAssembled, duration: 2.5)
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        showInstructions = false
                    }
                }
            }
        } else {
            // return to original position - remove bounce animation, directly reset state
            fanBones[index].isDragging = false
        }
    }

    // MARK: - Calculate fan bone rotation angle
    private func calculateRotation(for index: Int) -> Double {
        let totalBones = Double(AppConstants.targetFanBones)
        let startAngle = -AppConstants.fanSpreadAngle / 2
        return startAngle + (Double(index) / (totalBones - 1)) * AppConstants.fanSpreadAngle
    }

    // MARK: - toggle fan open/close
    private func toggleFan() {
        AudioManager.shared.play(.tap)
        AudioManager.shared.playHaptic(.light)

        withAnimation(.softSpring) {
            isOpen.toggle()
        }

        // if fan folded, trigger level complete
        if !isOpen {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                gameState.completeCurrentLevel()
            }
        }
    }
}

// MARK: - Fan Bone Shape
struct FanBoneShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let width = rect.width
        let height = rect.height

        // fan bone slightly curved
        path.move(to: CGPoint(x: 0, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: width * 0.4, y: height),
            control: CGPoint(x: width * 0.2, y: height * 0.5)
        )
        path.addLine(to: CGPoint(x: width * 0.6, y: height))
        path.addQuadCurve(
            to: CGPoint(x: width, y: 0),
            control: CGPoint(x: width * 0.8, y: height * 0.5)
        )
        path.closeSubpath()

        return path
    }
}

// MARK: - lottery bucket container
struct LotteryContainerView: View {
    var body: some View {
        ZStack {
            // bucket body
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.4, green: 0.3, blue: 0.2),
                            Color(red: 0.3, green: 0.25, blue: 0.18)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 180, height: 160)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(red: 0.5, green: 0.4, blue: 0.3), lineWidth: 3)
                )

            // bucket rim decoration
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(red: 0.35, green: 0.28, blue: 0.2))
                .frame(width: 190, height: 30)
                .offset(y: -75)

            // label
            Text("Fan Bones")
                .font(.system(size: 20, weight: .medium, design: .serif))
                .foregroundColor(Color(red: 0.9, green: 0.85, blue: 0.7))
                .offset(y: -75)
        }
    }
}

// MARK: - fan mold
struct FanMoldView: View {
    var body: some View {
        ZStack {
            // fan mold outline (rotated 180 degrees, fan face up)
            FanShape()
                .stroke(
                    Color(red: 0.7, green: 0.65, blue: 0.6),
                    style: StrokeStyle(lineWidth: 4, dash: [10, 5])
                )
                .frame(width: 320, height: 320)
                .opacity(0.5)
                .rotationEffect(.degrees(0))
                .offset(y: 200)  // offset downward

            // center dot hint
            Circle()
                .fill(Color(red: 0.7, green: 0.65, blue: 0.6).opacity(0.3))
                .frame(width: 30, height: 30)

            // guide lines (fan bone placement reference) - rotated 180 degrees
            ForEach(0..<7, id: \.self) { i in
                let angle = -60.0 + (Double(i) / 6.0) * 120.0
                Rectangle()
                    .fill(Color(red: 0.7, green: 0.65, blue: 0.6).opacity(0.2))
                    .frame(width: 1, height: 160)
                    .rotationEffect(.degrees(angle + 180), anchor: .top)  // change to top anchor, rotate 180 degrees
                    .offset(y: 80)  // offset downward
            }
        }
    }
}

#Preview {
    FanBonesAssemblyView()
        .environmentObject(GameState())
}
