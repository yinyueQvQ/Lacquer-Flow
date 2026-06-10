//
//  PoemOverlay.swift
//  Lacquer Art - Poem Overlay
//

import SwiftUI

struct PoemOverlay: View {
    let text: String
    let isVisible: Bool

    var body: some View {
        if isVisible {
            ZStack {
                // semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)

                // poem card
                Text(text)
                    .poemStyle()
                    .transition(
                        .asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        )
                    )
            }
            .zIndex(1000)
        }
    }
}

#Preview {
    PoemOverlay(text: "Lacquer's use began\nwith bamboo slips", isVisible: true)
}