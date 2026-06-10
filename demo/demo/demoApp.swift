//
//  demoApp.swift
//  Lacquer Art
//

import SwiftUI

@main
struct LacquerArtApp: App {
    init() {
        // Set global appearance
        setupAppearance()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
                .statusBar(hidden: true)
        }
    }

    // MARK: - Set Appearance
    private func setupAppearance() {
        // Disable multitasking gestures for more immersive experience
        // Note: this requires configuration in Info.plist
    }
}

// MARK: - Performance monitoring (development only)
#if DEBUG
struct PerformanceMonitor {
    static func logMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024.0 / 1024.0
            print("Memory used: \(String(format: "%.2f", usedMB)) MB")
        }
    }
}
#endif
