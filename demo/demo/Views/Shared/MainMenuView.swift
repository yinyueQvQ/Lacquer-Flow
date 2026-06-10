//
//  MainMenuView.swift
//  Lacquer Art - main menu
//

import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showContent = false
    @State private var showAbout = false
    @State private var showARView = false
    @State private var showARCraft = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // ink wash background
                RenderManager.shared.inkWashBackground()

                VStack(spacing: min(50, geometry.size.height * 0.06)) {
                    Spacer(minLength: geometry.size.height * 0.1)

                    // title section
                    VStack(spacing: min(15, geometry.size.height * 0.02)) {
                        Text("Lacquer Art")
                            .font(.system(size: min(80, geometry.size.width * 0.08), weight: .thin, design: .serif))
                            .foregroundColor(AppColors.vermillion)
                            .opacity(showContent ? 1 : 0)
                            .scaleEffect(showContent ? 1 : 0.8)
                            .minimumScaleFactor(0.5)
                            .lineLimit(1)

                        Text("Traditional Lacquer Fan Craft Interactive Experience")
                            .font(.system(size: min(32, geometry.size.width * 0.035), weight: .light, design: .serif))
                            .foregroundColor(AppColors.inkBlack.opacity(0.7))
                            .opacity(showContent ? 1 : 0)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: geometry.size.height * 0.08)

                    // menu buttons
                    VStack(spacing: min(25, geometry.size.height * 0.03)) {
                        // Quick Experience button
                        Button(action: {
                            AudioManager.shared.play(.tap)
                            AudioManager.shared.playHaptic(.medium)
                            withAnimation {
                                gameState.resetGame()
                                gameState.startGame()
                            }
                        }) {
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: min(28, geometry.size.width * 0.03)))
                                    Text("Quick Experience")
                                        .font(.system(size: min(38, geometry.size.width * 0.042), weight: .medium, design: .serif))
                                }
                                Text("3-5 minutes · Lacquering + Dyeing")
                                    .font(.system(size: min(16, geometry.size.width * 0.018), weight: .light, design: .serif))
                                    .opacity(0.9)
                            }
                            .foregroundColor(AppColors.paperWhite)
                            .padding(.horizontal, min(45, geometry.size.width * 0.05))
                            .padding(.vertical, min(20, geometry.size.height * 0.025))
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(AppColors.vermillion)
                                    .shadow(color: AppColors.vermillion.opacity(0.4), radius: 20, x: 0, y: 10)
                            )
                            .minimumScaleFactor(0.6)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                        // AR Craft Experience button
                        Button(action: {
                            AudioManager.shared.play(.tap)
                            AudioManager.shared.playHaptic(.medium)
                            withAnimation {
                                showARCraft = true
                            }
                        }) {
                            VStack(spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "cube.transparent")
                                        .font(.system(size: min(28, geometry.size.width * 0.03)))
                                    Text("AR Craft Experience")
                                        .font(.system(size: min(38, geometry.size.width * 0.042), weight: .medium, design: .serif))
                                }
                                Text("10-15 minutes · Full AR Creation")
                                    .font(.system(size: min(16, geometry.size.width * 0.018), weight: .light, design: .serif))
                                    .opacity(0.9)
                            }
                            .foregroundColor(AppColors.paperWhite)
                            .padding(.horizontal, min(45, geometry.size.width * 0.05))
                            .padding(.vertical, min(20, geometry.size.height * 0.025))
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(AppColors.goldLeaf)
                                    .shadow(color: AppColors.goldLeaf.opacity(0.4), radius: 20, x: 0, y: 10)
                            )
                            .minimumScaleFactor(0.6)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                        // AR View button
                        Button(action: {
                            AudioManager.shared.play(.tap)
                            AudioManager.shared.playHaptic(.light)
                            withAnimation {
                                showARView = true
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "arkit")
                                    .font(.system(size: min(20, geometry.size.width * 0.022)))
                                Text("AR Preview")
                                    .font(.system(size: min(22, geometry.size.width * 0.025), weight: .regular, design: .serif))
                            }
                            .foregroundColor(AppColors.inkBlack.opacity(0.7))
                            .padding(.horizontal, min(35, geometry.size.width * 0.04))
                            .padding(.vertical, min(13, geometry.size.height * 0.016))
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(AppColors.inkBlack.opacity(0.2), lineWidth: 2)
                            )
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)

                        // about button
                        Button(action: {
                            AudioManager.shared.play(.tap)
                            AudioManager.shared.playHaptic(.light)
                            withAnimation {
                                showAbout = true
                            }
                        }) {
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: min(20, geometry.size.width * 0.022)))
                                Text("About")
                                    .font(.system(size: min(22, geometry.size.width * 0.025), weight: .regular, design: .serif))
                            }
                            .foregroundColor(AppColors.inkBlack.opacity(0.7))
                            .padding(.horizontal, min(35, geometry.size.width * 0.04))
                            .padding(.vertical, min(13, geometry.size.height * 0.016))
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(AppColors.inkBlack.opacity(0.2), lineWidth: 2)
                            )
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: geometry.size.height * 0.1)

                    // bottom copyright info
                    Text("Swift Student Challenge 2025")
                        .font(.system(size: min(16, geometry.size.width * 0.018), weight: .light, design: .serif))
                        .foregroundColor(AppColors.inkBlack.opacity(0.5))
                        .opacity(showContent ? 1 : 0)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .padding(.bottom, 20)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            withAnimation(.slowEase.delay(0.3)) {
                showContent = true
            }
        }
        .fullScreenCover(isPresented: $showARView) {
            ARFanView()
        }
        .fullScreenCover(isPresented: $showARCraft) {
            ARCraftExperienceView()
        }
    }
}

#Preview {
    MainMenuView()
        .environmentObject(GameState())
}
