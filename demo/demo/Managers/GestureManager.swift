//
//  GestureManager.swift
//  Lacquer Art - Gesture Manager
//

import SwiftUI
import Combine

/// Gesture Manager
class GestureManager: ObservableObject {
    // MARK: - Drag State
    @Published var dragLocation: CGPoint = .zero
    @Published var isDragging: Bool = false
    @Published var dragStartLocation: CGPoint = .zero

    // MARK: - Scale State
    @Published var currentScale: CGFloat = 1.0
    @Published var finalScale: CGFloat = 1.0

    // MARK: - Carving Path Recording
    private var recordedPath: [CGPoint] = []
    private var lastRecordedPoint: CGPoint?
    private let minimumPointDistance: CGFloat = 3.0  // minimum point distance for optimization

    // MARK: - Drag Gesture Handling

    /// Start drag
    func onDragStart(at location: CGPoint) {
        dragStartLocation = location
        dragLocation = location
        isDragging = true
        recordedPath = [location]
        lastRecordedPoint = location
    }

    /// Dragging
    func onDragChange(to location: CGPoint) {
        dragLocation = location

        // Optimization: only record points far enough apart
        if let lastPoint = lastRecordedPoint {
            let distance = hypot(location.x - lastPoint.x, location.y - lastPoint.y)
            if distance >= minimumPointDistance {
                recordedPath.append(location)
                lastRecordedPoint = location
            }
        } else {
            recordedPath.append(location)
            lastRecordedPoint = location
        }
    }

    /// End drag
    func onDragEnd() {
        isDragging = false
    }

    /// Get recorded path
    func getRecordedPath() -> [CGPoint] {
        return recordedPath
    }

    /// Clear path
    func clearPath() {
        recordedPath = []
        lastRecordedPoint = nil
    }

    // MARK: - Scale Gesture Handling

    /// Scale start
    func onScaleStart() {
        currentScale = finalScale
    }

    /// Scaling
    func onScaleChange(_ scale: CGFloat) {
        currentScale = finalScale * scale
    }

    /// Scale end
    func onScaleEnd() {
        finalScale = currentScale
    }

    /// Reset scale
    func resetScale() {
        withAnimation(.spring()) {
            currentScale = 1.0
            finalScale = 1.0
        }
    }

    // MARK: - Utility Methods

    /// Check if point is within specified area
    func isPoint(_ point: CGPoint, inRect rect: CGRect) -> Bool {
        return rect.contains(point)
    }

    /// Calculate distance between two points
    func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
        return hypot(point2.x - point1.x, point2.y - point1.y)
    }

    /// Calculate total path length
    func pathLength() -> CGFloat {
        var length: CGFloat = 0
        for i in 1..<recordedPath.count {
            length += distance(from: recordedPath[i-1], to: recordedPath[i])
        }
        return length
    }

    /// Simplify path (simplified Douglas-Peucker algorithm)
    func simplifyPath(_ points: [CGPoint], tolerance: CGFloat = 5.0) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var simplified: [CGPoint] = [points.first!]
        var lastPoint = points.first!

        for point in points.dropFirst() {
            let dist = distance(from: lastPoint, to: point)
            if dist >= tolerance {
                simplified.append(point)
                lastPoint = point
            }
        }

        // Ensure last point is included
        if simplified.last != points.last {
            simplified.append(points.last!)
        }

        return simplified
    }
}