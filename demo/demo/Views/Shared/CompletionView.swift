//
//  CompletionView.swift
//  Lacquer Art - Completion View
//

import SwiftUI

struct CompletionView: View {
    let title: String
    let message: String
    let score: Int?
    let onContinue: () -> Void

    @State private var showContent = false
    @State private var showButton = false

    var body: some View {
        ZStack {
            // Background
            RenderManager.shared.inkWashBackground()

            VStack(spacing: 40) {
                // Title
                Text(title)
                    .font(AppFonts.title())
                    .foregroundColor(AppColors.vermillion)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)

                // Message
                Text(message)
                    .font(AppFonts.subtitle())
                    .foregroundColor(AppColors.inkBlack)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : -20)

                // Score (if available)
                if let score = score {
                    VStack(spacing: 10) {
                        Text("Craftsmanship Score")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.inkBlack.opacity(0.7))

                        Text("\(score)")
                            .font(.system(size: 72, weight: .light, design: .serif))
                            .foregroundColor(AppColors.goldLeaf)
                    }
                    .opacity(showContent ? 1 : 0)
                    .scaleEffect(showContent ? 1 : 0.5)
                }

                // Continue button
                Button(action: onContinue) {
                    Text("Continue")
                        .font(AppFonts.body())
                        .foregroundColor(AppColors.paperWhite)
                        .padding(.horizontal, 60)
                        .padding(.vertical, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 30)
                                .fill(AppColors.vermillion)
                                .shadow(color: AppColors.vermillion.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                }
                .opacity(showButton ? 1 : 0)
                .scaleEffect(showButton ? 1 : 0.8)
            }
            .padding(40)
        }
        .onAppear {
            withAnimation(.slowEase.delay(0.3)) {
                showContent = true
            }
            withAnimation(.slowEase.delay(1.0)) {
                showButton = true
            }
        }
    }
}

#Preview {
    CompletionView(
        title: "Level Complete",
        message: "Layer upon layer\nA hundred coats applied",
        score: 85,
        onContinue: {}
    )
}