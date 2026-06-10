//
//  FreeCreationView.swift
//  Lacquer Art - Free Creation Mode
//

import SwiftUI

struct FreeCreationView: View {
    @EnvironmentObject var gameState: GameState
    @Environment(\.dismiss) var dismiss

    // creation state
    @State private var currentMode: CreationMode = .lacquering
    @State private var selectedColor: LacquerType = .red
    @State private var lacquerLayers: [LacquerType] = []
    @State private var carvingPaths: [DyeingPath] = []
    @State private var currentPath: [CGPoint] = []
    @State private var showColorPicker = true
    @State private var rotationAngle: Double = 0
    @State private var isRotating = false
    @State private var haslacquer = false

    // creation mode
    enum CreationMode {
        case lacquering  // lacquering mode
        case carving     // carving mode
        case preview     // preview mode
    }

    var body: some View {
        ZStack {
            // background
            LinearGradient(
                colors: [
                    Color(red: 0.15, green: 0.15, blue: 0.17),
                    Color(red: 0.1, green: 0.1, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // top toolbar
                TopToolBar(
                    currentMode: $currentMode,
                    onDismiss: { dismiss() },
                    onSave: saveCreation,
                    onClear: clearCanvas
                )

                Spacer()

                // creation canvas
                if currentMode == .preview {
                    // 3D preview mode
                    PreviewCanvas(
                        lacquerLayers: lacquerLayers,
                        carvingPaths: carvingPaths,
                        rotationAngle: $rotationAngle,
                        isRotating: $isRotating
                    )
                    .frame(width: 350, height: 350) // adjust size
                    .offset(y: 100) // offset slightly downward
                } else {
                    // creation canvas
                    CreationCanvas(
                        mode: currentMode,
                        lacquerLayers: $lacquerLayers,
                        carvingPaths: $carvingPaths,
                        currentPath: $currentPath,
                        selectedColor: selectedColor,
                        haslacquer: $haslacquer
                    )
                    .frame(width: 350, height: 350) // adjust size
                    .offset(y: 100) // offset slightly downward
                }
                Spacer()

                // bottom tool panel
                BottomToolPanel(
                    currentMode: currentMode,
                    selectedColor: $selectedColor,
                    haslacquer: $haslacquer,
                    lacquerCount: lacquerLayers.count
                )
            }

            // poem hint
            PoemOverlay(text: gameState.currentPoem, isVisible: gameState.showPoem)
        }
        .onAppear {
            gameState.showPoem("Free Expression · Craftsmanship Revealed", duration: 2.0)
        }
    }

    // MARK: - Save Creation
    private func saveCreation() {
        AudioManager.shared.play(.tap)
        AudioManager.shared.playNotificationHaptic(.success)
        // TODO: implement save to photo album feature
        gameState.showPoem("Artwork Saved", duration: 2.0)
    }

    // MARK: - Clear Canvas
    private func clearCanvas() {
        AudioManager.shared.play(.tap)
        withAnimation {
            lacquerLayers.removeAll()
            carvingPaths.removeAll()
            currentPath.removeAll()
        }
        gameState.showPoem("Canvas Cleared", duration: 1.5)
    }
}

// MARK: - top toolbar
struct TopToolBar: View {
    @Binding var currentMode: FreeCreationView.CreationMode
    let onDismiss: () -> Void
    let onSave: () -> Void
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 20) {
            // return button
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppColors.paperWhite)
            }

            Spacer()

            // mode switch
            HStack(spacing: 15) {
                ModeButton(
                    icon: "paintbrush.fill",
                    title: "Lacquering",
                    isSelected: currentMode == .lacquering
                ) {
                    withAnimation { currentMode = .lacquering }
                }

                ModeButton(
                    icon: "pencil.tip",
                    title: "Carving",
                    isSelected: currentMode == .carving
                ) {
                    withAnimation { currentMode = .carving }
                }

                ModeButton(
                    icon: "cube.fill",
                    title: "Preview",
                    isSelected: currentMode == .preview
                ) {
                    withAnimation { currentMode = .preview }
                }
            }

            Spacer()

            // function buttons
            HStack(spacing: 15) {
                Button(action: onClear) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(AppColors.paperWhite)
                }

                Button(action: onSave) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.title3)
                        .foregroundColor(AppColors.goldLeaf)
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.top, 50)
        .padding(.bottom, 20)
    }
}

// MARK: - Mode Buttons
struct ModeButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            AudioManager.shared.play(.tap)
            action()
        }) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(AppFonts.caption())
            }
            .foregroundColor(isSelected ? AppColors.goldLeaf : AppColors.paperWhite.opacity(0.6))
            .frame(width: 70)
        }
    }
}

// MARK: - creation canvas
struct CreationCanvas: View {
    let mode: FreeCreationView.CreationMode
    @Binding var lacquerLayers: [LacquerType]
    @Binding var carvingPaths: [DyeingPath]
    @Binding var currentPath: [CGPoint]
    let selectedColor: LacquerType
    @Binding var haslacquer: Bool

    @State private var isDragging = false

    // unified position offset
    private let canvasOffset: CGFloat = 150 // adjust to more suitable value

    var body: some View {
        ZStack {
            // wooden base
            FanShape()
                .offset(y: canvasOffset)
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

            // show each lacquer layer (with carving effect)
            ForEach(Array(lacquerLayers.enumerated()), id: \.offset) { index, color in
                FanShape()
                    .offset(y: canvasOffset)
                    .fill(
                        RadialGradient(
                            colors: [
                                color.color.opacity(0.75),
                                color.color.opacity(0.65)
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .opacity(0.35 + Double(index) * 0.05)
                    .modifier(
                        // only apply mask when there are carving paths
                        CarvingMaskModifier(
                            shouldApplyMask: !carvingPaths.isEmpty || !currentPath.isEmpty,
                            carvingPaths: carvingPaths,
                            currentPath: mode == .carving ? currentPath : [],
                            layerIndex: index,
                            totalLayers: lacquerLayers.count,
                            canvasOffset: canvasOffset
                        )
                    )
            }

            // gloss effect
            FanShape()
                .offset(y: canvasOffset)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(Double(lacquerLayers.count) / 100.0),
                            Color.clear,
                            Color.white.opacity(Double(lacquerLayers.count) / 150.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)

            // border
            FanShape()
                .offset(y: canvasOffset)
                .stroke(AppColors.goldLeaf.opacity(0.3), lineWidth: 2)
        }
        // fix: use correct contentShape
        .contentShape(Rectangle()) // use rectangle as gesture area, covering entire view
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    handleDrag(value)
                }
                .onEnded { _ in
                    handleDragEnd()
                }
        )
    }

    private func handleDrag(_ value: DragGesture.Value) {
        let location = value.location

        if mode == .lacquering {
            // lacquering mode - can lacquer as long as there is lacquer liquid
            if haslacquer {
                AudioManager.shared.play(.tap)
                lacquerLayers.append(selectedColor)
                haslacquer = false
            }
        } else if mode == .carving {
            // carving mode - convert touch coordinates to coordinates relative to fan surface center
            // fan surface center position in view coordinate system: (175, 175 + canvasOffset)
            let adjustedLocation = CGPoint(
                x: location.x - 175,
                y: location.y - (175 + canvasOffset)
            )

            if !isDragging {
                isDragging = true
                currentPath = [adjustedLocation]
                AudioManager.shared.play(.carve)
            } else {
                if let last = currentPath.last {
                    let distance = hypot(
                        adjustedLocation.x - last.x,
                        adjustedLocation.y - last.y
                    )
                    if distance >= 3.0 {
                        currentPath.append(adjustedLocation)
                    }
                }
            }
            AudioManager.shared.playHaptic(.light)
        }
    }

    private func handleDragEnd() {
        if mode == .carving && currentPath.count > 1 {
            carvingPaths.append(DyeingPath(
                points: currentPath,
                lineWidth: AppConstants.dyeingBrushWidth
            ))
            AudioManager.shared.playNotificationHaptic(.success)
        }
        currentPath = []
        isDragging = false
    }
}

// MARK: - Carving Mask Modifier
struct CarvingMaskModifier: ViewModifier {
    let shouldApplyMask: Bool
    let carvingPaths: [DyeingPath]
    let currentPath: [CGPoint]
    let layerIndex: Int
    let totalLayers: Int
    let canvasOffset: CGFloat

    func body(content: Content) -> some View {
        if shouldApplyMask {
            content
                .mask {
                    CarvingMask(
                        carvingPaths: carvingPaths,
                        currentPath: currentPath,
                        layerIndex: layerIndex,
                        totalLayers: totalLayers
                    )
                    .offset(y: canvasOffset)
                }
        } else {
            content
        }
    }
}

// MARK: - Carving Mask
struct CarvingMask: View {
    let carvingPaths: [DyeingPath]
    let currentPath: [CGPoint]
    let layerIndex: Int
    let totalLayers: Int

    var body: some View {
        Canvas { context, size in
            // white background
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .color(.white)
            )

            // carving paths
            context.blendMode = .destinationOut
            let depthForThisLayer = Double(totalLayers - layerIndex - 1) * 3.0

            for carvingPath in carvingPaths {
                var path = Path()
                if let first = carvingPath.points.first {
                    path.move(to: first)
                    for point in carvingPath.points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                let adjustedLineWidth = max(0, carvingPath.lineWidth - depthForThisLayer)
                if adjustedLineWidth > 0 {
                    context.stroke(
                        path,
                        with: .color(.black),
                        lineWidth: adjustedLineWidth
                    )
                }
            }

            // current path
            if !currentPath.isEmpty {
                var path = Path()
                path.move(to: currentPath[0])
                for point in currentPath.dropFirst() {
                    path.addLine(to: point)
                }
                let adjustedLineWidth = max(0, AppConstants.dyeingBrushWidth - depthForThisLayer)
                if adjustedLineWidth > 0 {
                    context.stroke(
                        path,
                        with: .color(.black),
                        lineWidth: adjustedLineWidth
                    )
                }
            }
        }
    }
}

// MARK: - Preview Canvas
struct PreviewCanvas: View {
    let lacquerLayers: [LacquerType]
    let carvingPaths: [DyeingPath]
    @Binding var rotationAngle: Double
    @Binding var isRotating: Bool

    // add offset to move preview fan downward
    private let previewOffset: CGFloat = 80

    var body: some View {
        ZStack {
            // wooden base
            FanShape()
                .offset(y: previewOffset) // add offset
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

            // Lacquer Layers
            ForEach(Array(lacquerLayers.enumerated()), id: \.offset) { index, color in
                FanShape()
                    .offset(y: previewOffset) // add offset
                    .fill(
                        RadialGradient(
                            colors: [
                                color.color.opacity(0.75),
                                color.color.opacity(0.65)
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 200
                        )
                    )
                    .opacity(0.35 + Double(index) * 0.05)
                    .mask {
                        if !carvingPaths.isEmpty {
                            CarvingMask(
                                carvingPaths: carvingPaths,
                                currentPath: [],
                                layerIndex: index,
                                totalLayers: lacquerLayers.count
                            )
                            .offset(y: previewOffset) // add offset
                        }
                    }
            }

            // gloss
            FanShape()
                .offset(y: previewOffset) // add offset
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(Double(lacquerLayers.count) / 100.0),
                            Color.clear,
                            Color.white.opacity(Double(lacquerLayers.count) / 150.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)

            // gold border
            FanShape()
                .offset(y: previewOffset) // add offset
                .stroke(AppColors.goldLeaf, lineWidth: 3)
                .opacity(0.6)
        }
        .rotation3DEffect(
            .degrees(rotationAngle),
            axis: (x: 0, y: 1, z: 0)
        )
        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 20)
        .onAppear {
            startRotation()
        }
    }

    private func startRotation() {
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }
}
// MARK: - bottom tool panel
struct BottomToolPanel: View {
    let currentMode: FreeCreationView.CreationMode
    @Binding var selectedColor: LacquerType
    @Binding var haslacquer: Bool
    let lacquerCount: Int
    @State private var hasShownPickupPoem = false  // whether lacquer pickup hint has been shown

    var body: some View {
        VStack(spacing: 20) {
            if currentMode == .lacquering {
                // lacquering tools
                VStack(spacing: 15) {
                    // color selection
                    ColorPickerView(
                        selectedColor: $selectedColor,
                        onColorSelected: { color in
                            selectedColor = color
                        }
                    )
                    .frame(height: 80)

                    // lacquer bowl
                    HStack(spacing: 60) {
                        VStack {
                            Circle()
                                .fill(
                                    RenderManager.shared.lacquerBowlGradient(for: selectedColor)
                                )
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle()
                                        .stroke(Color.black.opacity(0.3), lineWidth: 3)
                                )
                                .onTapGesture {
                                    pickUpLacquer()
                                }

                            Text(selectedColor.name)
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.paperWhite.opacity(0.7))
                        }

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
                                .foregroundColor(AppColors.paperWhite.opacity(0.7))
                        }
                    }

                    // Lacquer layers count
                    Text("\(lacquerCount) layers applied")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.goldLeaf)
                }
            } else if currentMode == .carving {
                // carving tools hint
                VStack(spacing: 10) {
                    Image(systemName: "hand.draw")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.paperWhite.opacity(0.5))

                    Text("Slide finger on fan surface to carve")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.paperWhite.opacity(0.7))
                }
            } else {
                // preview mode hint
                VStack(spacing: 10) {
                    Image(systemName: "cube.transparent")
                        .font(.largeTitle)
                        .foregroundColor(AppColors.paperWhite.opacity(0.5))

                    Text("360° rotating preview of your artwork")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.paperWhite.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
    }

    private func pickUpLacquer() {
        AudioManager.shared.play(.lacquer)
        AudioManager.shared.playHaptic(.light)
        haslacquer = true

        // only show hint on first lacquer pickup
        if !hasShownPickupPoem {
            // need to access gameState, but BottomToolPanel doesn't have it, so remove hint or pass in gameState
            hasShownPickupPoem = true
        }
    }
}

#Preview {
    FreeCreationView()
        .environmentObject(GameState())
}
