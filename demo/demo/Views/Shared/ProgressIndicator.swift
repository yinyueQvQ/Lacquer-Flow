//
//  ProgressIndicator.swift
//  Lacquer Art - Progress Indicator
//

import SwiftUI

struct ProgressIndicator: View {
    let progress: Double
    let total: Double
    let label: String

    var body: some View {
        VStack(spacing: 10) {
            // progress text
            HStack {
                Text(label)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.inkBlack)

                Spacer()

                Text("\(Int(progress)) / \(Int(total))")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.inkBlack.opacity(0.7))
            }

            // progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // background
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppColors.inkBlack.opacity(0.1))

                    // progress
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.vermillion,
                                    AppColors.goldLeaf
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (progress / total))
                        .animation(.lightSpring, value: progress)
                }
            }
            .frame(height: 20)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.paperWhite.opacity(0.9))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    ProgressIndicator(progress: 7, total: 10, label: "Lacquer Layers")
        .padding()
}