//
//  FanArtwork.swift
//  Lacquer Art - Artwork Data Model
//

import SwiftUI
import Combine

/// Fan Bone Data
struct FanBone: Identifiable, Codable {
    let id = UUID()
    var index: Int              // fan bone index (0-6)
    var position: CGPoint       // current position
    var rotation: Double        // rotation angle
    var isAssembled: Bool       // is assembled

    /// Calculate target position of fan bone (when open)
    func targetPosition(in size: CGSize) -> CGPoint {
        let centerX = size.width / 2
        let centerY = size.height * 0.7
        return CGPoint(x: centerX, y: centerY)
    }

    /// Calculate target rotation angle of fan bones
    func targetRotation() -> Double {
        let totalBones = 7.0
        let spreadAngle = 120.0 // spread angle 120 degrees
        let startAngle = -60.0  // start from -60 degrees
        return startAngle + (Double(index) / (totalBones - 1)) * spreadAngle
    }
}

/// Dyeing Path Data
struct DyeingPath: Identifiable, Codable {
    let id = UUID()
    var points: [CGPoint]       // path points collection
    var color: Color = .black   // base color
    var lineWidth: Double = 15.0 // line width (dyeing brush width)

    enum CodingKeys: String, CodingKey {
        case id, points, lineWidth
    }

    init(points: [CGPoint] = [], color: Color = .black, lineWidth: Double = 15.0) {
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
    }

    // Codable support
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(UUID.self, forKey: .id)
        let points = try container.decode([CGPoint].self, forKey: .points)
        let lineWidth = try container.decode(Double.self, forKey: .lineWidth)
        self.init(points: points, color: .black, lineWidth: lineWidth)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(points, forKey: .points)
        try container.encode(lineWidth, forKey: .lineWidth)
    }
}

/// Complete Fan Artwork
class FanArtwork: ObservableObject, Identifiable {
    let id = UUID()

    // MARK: - Fan Bone Data
    @Published var fanBones: [FanBone] = []

    // MARK: - Lacquer Layer Data
    @Published var lacquerLayers: [LacquerMaterial] = []
    @Published var currentLacquer: LacquerMaterial

    // MARK: - Dyeing Data
    @Published var dyeingPaths: [DyeingPath] = []
    @Published var currentPath: [CGPoint] = []

    // MARK: - Artwork State
    @Published var isOpen: Bool = true      // is fan open
    @Published var rotationAngle: Double = 0.0  // 3Drotation angle

    init() {
        // initialize lacquer materials
        currentLacquer = LacquerMaterial(type: .black)

        // initialize 7 fan bones
        for i in 0..<7 {
            fanBones.append(FanBone(
                index: i,
                position: .zero,
                rotation: 0,
                isAssembled: false
            ))
        }
    }

    // MARK: - Fan Bone Operations

    /// Assemble fan bone
    func assembleBone(at index: Int) {
        guard index < fanBones.count else { return }
        fanBones[index].isAssembled = true
        fanBones[index].rotation = fanBones[index].targetRotation()
    }

    /// Toggle fan open/close state
    func toggleFan() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isOpen.toggle()
        }
    }

    // MARK: - Lacquering Operations

    /// Add a layer of lacquer
    func addLacquerLayer() {
        var newLayer = currentLacquer
        newLayer.increaseThickness()
        lacquerLayers.append(newLayer)

        // update current lacquer gloss
        currentLacquer.increaseGlossiness()
    }

    /// Switch lacquer type
    func switchLacquer(to type: LacquerType) {
        currentLacquer = LacquerMaterial(type: type)
    }

    // MARK: - Dyeing Operations

    /// Start new dyeing path
    func startDyeing(at point: CGPoint) {
        currentPath = [point]
    }

    /// Continue dyeing path
    func continueDyeing(to point: CGPoint) {
        currentPath.append(point)
    }

    /// Complete current dyeing path
    func finishDyeing() {
        if !currentPath.isEmpty {
            let path = DyeingPath(points: currentPath)
            dyeingPaths.append(path)
            currentPath = []
        }
    }

    /// Calculate dyeing coverage (for completion determination)
    func dyeingCoverage(in size: CGSize) -> Double {
        let totalPoints = dyeingPaths.reduce(0) { $0 + $1.points.count }
        // assume about 500 points needed for completion
        return min(1.0, Double(totalPoints) / 500.0)
    }

    // MARK: - 3D Presentation

    /// Start 3D rotation animation
    func startRotation() {
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
    }

    /// Stop rotation
    func stopRotation() {
        withAnimation(.easeOut(duration: 0.5)) {
            rotationAngle = 0
        }
    }
}