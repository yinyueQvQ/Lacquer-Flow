//
//  ARCraftExperienceView.swift
//  Lacquer Art - AR Craft Experience (Feature 2)
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARCraftExperienceView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var craftState = ARCraftState()

    var body: some View {
        ZStack {
            ARCraftContainer(craftState: craftState)
                .ignoresSafeArea()

            VStack {
                // Top bar
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }

                    Spacer()

                    Text(craftState.currentStage.title)
                        .font(AppFonts.title())
                        .foregroundColor(.white)
                        .padding()
                        .background(Capsule().fill(Color.black.opacity(0.5)))

                    Spacer()

                    Button(action: { craftState.nextStage() }) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .opacity(craftState.canProceed ? 1 : 0.3)
                    .disabled(!craftState.canProceed)
                }
                .padding()

                Spacer()

                // Bottom controls
                ARCraftControlsView(craftState: craftState)
            }
        }
    }
}

// MARK: - AR Craft State
class ARCraftState: ObservableObject {
    @Published var currentStage: CraftStage = .preparation
    @Published var lacquerLayers: Int = 0
    @Published var baseColor: LacquerType = .black
    @Published var decorationPaths: [DyeingPath] = []
    @Published var selectedTechnique: DecorationTechnique = .gradient
    @Published var selectedColor: LacquerType = .red
    @Published var canProceed: Bool = false

    enum CraftStage {
        case preparation    // 材料准备
        case lacquering     // 髹漆工艺
        case decoration     // 染色装饰
        case presentation   // 完成展示

        var title: String {
            switch self {
            case .preparation: return "Material Preparation"
            case .lacquering: return "Lacquering Process"
            case .decoration: return "Decoration"
            case .presentation: return "Final Artwork"
            }
        }
    }

    enum DecorationTechnique {
        case gradient  // 晕染
        case dotting   // 点彩
        case gilding   // 描金
    }

    func nextStage() {
        switch currentStage {
        case .preparation:
            currentStage = .lacquering
        case .lacquering:
            currentStage = .decoration
        case .decoration:
            currentStage = .presentation
        case .presentation:
            break
        }
        updateCanProceed()
    }

    func addLacquerLayer() {
        lacquerLayers += 1
        updateCanProceed()
    }

    func updateCanProceed() {
        switch currentStage {
        case .preparation:
            canProceed = true
        case .lacquering:
            canProceed = lacquerLayers >= 10
        case .decoration:
            canProceed = decorationPaths.count >= 5
        case .presentation:
            canProceed = false
        }
    }
}

// MARK: - AR Container
struct ARCraftContainer: UIViewRepresentable {
    @ObservedObject var craftState: ARCraftState

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        loadFanModel(into: arView)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // Update fan appearance based on craft state
    }

    private func loadFanModel(into arView: ARView) {
        guard let modelEntity = try? Entity.load(named: "acient_fan") else {
            print("Failed to load fan model")
            return
        }

        let anchor = AnchorEntity(.camera)
        anchor.addChild(modelEntity)

        modelEntity.scale = [0.02, 0.02, 0.02]
        modelEntity.position = [0, -0.1, -0.3]

        arView.scene.addAnchor(anchor)
    }
}

// MARK: - Controls View
struct ARCraftControlsView: View {
    @ObservedObject var craftState: ARCraftState

    var body: some View {
        VStack(spacing: 20) {
            switch craftState.currentStage {
            case .preparation:
                PreparationControls(craftState: craftState)

            case .lacquering:
                LacqueringControls(craftState: craftState)

            case .decoration:
                DecorationControls(craftState: craftState)

            case .presentation:
                PresentationControls(craftState: craftState)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.7))
        )
        .padding()
    }
}

// MARK: - Preparation Controls
struct PreparationControls: View {
    @ObservedObject var craftState: ARCraftState

    var body: some View {
        VStack(spacing: 15) {
            Text("Choose Base Color")
                .font(AppFonts.subtitle())
                .foregroundColor(.white)

            HStack(spacing: 20) {
                ForEach([LacquerType.black, LacquerType.red], id: \.self) { color in
                    Button(action: {
                        craftState.baseColor = color
                        AudioManager.shared.play(.tap)
                    }) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 60, height: 60)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: craftState.baseColor == color ? 4 : 0)
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Lacquering Controls
struct LacqueringControls: View {
    @ObservedObject var craftState: ARCraftState

    var body: some View {
        VStack(spacing: 15) {
            Text("Layers: \(craftState.lacquerLayers) / 15")
                .font(AppFonts.body())
                .foregroundColor(.white)

            ProgressView(value: Double(craftState.lacquerLayers), total: 15.0)
                .tint(AppColors.goldLeaf)

            Button(action: {
                craftState.addLacquerLayer()
                AudioManager.shared.play(.lacquer)
            }) {
                Text("Apply Lacquer Layer")
                    .font(AppFonts.body())
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.vermillion)
                    )
            }
            .disabled(craftState.lacquerLayers >= 15)
        }
    }
}

// MARK: - Decoration Controls
struct DecorationControls: View {
    @ObservedObject var craftState: ARCraftState

    var body: some View {
        VStack(spacing: 15) {
            // Technique selector
            HStack(spacing: 15) {
                TechniqueButton(
                    icon: "paintbrush.fill",
                    title: "Gradient",
                    isSelected: craftState.selectedTechnique == .gradient
                ) {
                    craftState.selectedTechnique = .gradient
                }

                TechniqueButton(
                    icon: "circle.fill",
                    title: "Dotting",
                    isSelected: craftState.selectedTechnique == .dotting
                ) {
                    craftState.selectedTechnique = .dotting
                }

                TechniqueButton(
                    icon: "sparkles",
                    title: "Gilding",
                    isSelected: craftState.selectedTechnique == .gilding
                ) {
                    craftState.selectedTechnique = .gilding
                }
            }

            // Color picker
            HStack(spacing: 10) {
                ForEach([LacquerType.red, LacquerType.gold, LacquerType.green, LacquerType.blue, LacquerType.black], id: \.self) { color in
                    Button(action: {
                        craftState.selectedColor = color
                        AudioManager.shared.play(.tap)
                    }) {
                        Circle()
                            .fill(color.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: craftState.selectedColor == color ? 3 : 0)
                            )
                    }
                }
            }
        }
    }
}

// MARK: - Presentation Controls
struct PresentationControls: View {
    @ObservedObject var craftState: ARCraftState

    var body: some View {
        VStack(spacing: 15) {
            Text("Your Artwork is Complete!")
                .font(AppFonts.title())
                .foregroundColor(.white)

            HStack(spacing: 20) {
                Button(action: {
                    // Save artwork
                    AudioManager.shared.play(.success)
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.down")
                            .font(.title)
                        Text("Save")
                            .font(AppFonts.caption())
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.goldLeaf)
                    )
                }

                Button(action: {
                    // Share artwork
                    AudioManager.shared.play(.tap)
                }) {
                    VStack {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title)
                        Text("Share")
                            .font(AppFonts.caption())
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(AppColors.vermillion)
                    )
                }
            }
        }
    }
}

// MARK: - Technique Button
struct TechniqueButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(AppFonts.caption())
            }
            .foregroundColor(isSelected ? AppColors.goldLeaf : .white)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.white.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppColors.goldLeaf : Color.white.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
}

#Preview {
    ARCraftExperienceView()
}