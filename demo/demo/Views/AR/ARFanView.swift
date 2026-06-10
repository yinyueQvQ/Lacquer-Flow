//
//  ARFanView.swift
//  Lacquer Art - AR Visualization
//

import SwiftUI
import RealityKit
import ARKit

struct ARFanView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showInstructions = true

    var body: some View {
        ZStack {
            ARViewContainer()
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()

                    Spacer()
                }

                Spacer()

                if showInstructions {
                    VStack(spacing: 10) {
                        Image(systemName: "hand.tap.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)

                        Text("Move your device to place the fan")
                            .font(AppFonts.body())
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 15)
                                    .fill(Color.black.opacity(0.7))
                            )
                    }
                    .padding(.bottom, 50)
                    .transition(.opacity)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showInstructions = false
                }
            }
        }
    }
}

struct ARViewContainer: UIViewRepresentable {
    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        loadFanModel(into: arView)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    private func loadFanModel(into arView: ARView) {
        guard let modelEntity = try? Entity.load(named: "acient_fan") else {
            print("Failed to load fan model")
            return
        }

        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(modelEntity)

        modelEntity.scale = [0.1, 0.1, 0.1]
        modelEntity.position = [0, 0, -0.5]

        arView.scene.addAnchor(anchor)
    }
}

#Preview {
    ARFanView()
}