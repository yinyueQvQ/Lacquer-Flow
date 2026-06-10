//
//  ContentView.swift
//  Lacquer Art - Main View (Navigation Control)
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameState = GameState()
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                GameNavigationView()
                    .environmentObject(gameState)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Show splash screen for 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.slowEase) {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8

    var body: some View {
        ZStack {
            // ink wash background
            RenderManager.shared.inkWashBackground()

            VStack(spacing: 40) {
                // main title
                Text("Lacquer Art")
                    .font(.system(size: 72, weight: .thin, design: .serif))
                    .foregroundColor(AppColors.vermillion)
                    .opacity(opacity)
                    .scaleEffect(scale)

                // subtitle
                Text("Traditional Lacquer Fan Craft Interactive Experience")
                    .font(AppFonts.subtitle())
                    .foregroundColor(AppColors.inkBlack.opacity(0.7))
                    .opacity(opacity)

                // decorative line
                HStack(spacing: 20) {
                    ForEach(0..<3, id: \.self) { _ in
                        Circle()
                            .fill(AppColors.goldLeaf)
                            .frame(width: 8, height: 8)
                    }
                }
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}

// MARK: - Game Navigation View
struct GameNavigationView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showMenu = false
    @State private var showFreeCreation = false  // Free Creation interface

    var body: some View {
        ZStack {
            // show different views based on current phase
            Group {
                switch gameState.currentPhase {
                case .mainMenu:
                    MainMenuView()

                case .firstAct:
                    FirstActNavigationView()

                case .secondAct:
                    SecondActNavigationView()

                case .completed:
                    CompletedView()
                }
            }
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))

            // menu buttons (shown when not in main menu or completed state)
            if gameState.currentPhase != .mainMenu && gameState.currentPhase != .completed {
                VStack {
                    HStack {
                        Spacer()

                        Button(action: {
                            AudioManager.shared.play(.tap)
                            withAnimation {
                                showMenu = true
                            }
                        }) {
                            Image(systemName: "line.3.horizontal")
                                .font(.title2)
                                .foregroundColor(AppColors.inkBlack)
                                .padding(15)
                                .background(
                                    Circle()
                                        .fill(AppColors.paperWhite.opacity(0.9))
                                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                )
                        }
                        .padding(.top, 50)
                        .padding(.trailing, 40)
                    }

                    Spacer()
                }
            }

            // Level Menu
            if showMenu {
                LevelMenuView(isPresented: $showMenu, showFreeCreation: $showFreeCreation)
                    .environmentObject(gameState)
                    .transition(.opacity)
                    .zIndex(1000)
            }
        }
        .fullScreenCover(isPresented: $showFreeCreation) {
            FreeCreationView()
                .environmentObject(gameState)
        }
        .animation(.easeInOut(duration: 0.6), value: gameState.currentPhase)
        .animation(.easeInOut(duration: 0.6), value: gameState.firstActLevel)
        .animation(.easeInOut(duration: 0.6), value: gameState.secondActLevel)
        .animation(.quickEase, value: showMenu)
    }
}

// MARK: - First Act Navigation
struct FirstActNavigationView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        Group {
            switch gameState.firstActLevel {
            case .lacquerCollection:
                LacquerCollectionView()

            case .fanBones:
                FanBonesAssemblyView()

            case .decoration:
                DecorationView()
            }
        }
    }
}

// MARK: - Second Act Navigation
struct SecondActNavigationView: View {
    @EnvironmentObject var gameState: GameState

    var body: some View {
        Group {
            switch gameState.secondActLevel {
            case .lacquering:
                LacqueringStepView()

            case .dyeing:
                DyeingStepView()

            case .presentation:
                PresentationStepView()
            }
        }
    }
}

// MARK: - Completion View
struct CompletedView: View {
    @EnvironmentObject var gameState: GameState
    @State private var showContent = false

    var body: some View {
        ZStack {
            // background
            RenderManager.shared.inkWashBackground()

            VStack(spacing: 60) {
                Spacer()

                // title
                VStack(spacing: 20) {
                    Text("Heritage")
                        .font(.system(size: 80, weight: .thin, design: .serif))
                        .foregroundColor(AppColors.vermillion)

                    Text("Lacquer Art · Millennium Craft")
                        .font(AppFonts.title())
                        .foregroundColor(AppColors.inkBlack)

                    // poem
                    Text(Poems.actTwoComplete)
                        .font(AppFonts.poem())
                        .foregroundColor(AppColors.inkBlack.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.top, 40)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)

                Spacer()

                // action buttons
                VStack(spacing: 20) {
                    Button(action: {
                        gameState.resetGame()
                    }) {
                        Text("Experience Again")
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.paperWhite)
                            .padding(.horizontal, 60)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 30)
                                    .fill(AppColors.vermillion)
                                    .shadow(color: AppColors.vermillion.opacity(0.3), radius: 15, x: 0, y: 8)
                            )
                    }

                    Text("Thank you for your experience")
                        .font(AppFonts.caption())
                        .foregroundColor(AppColors.inkBlack.opacity(0.6))
                }
                .opacity(showContent ? 1 : 0)

                Spacer()
            }
            .padding(60)
        }
        .onAppear {
            withAnimation(.slowEase.delay(0.5)) {
                showContent = true
            }
        }
    }
}

#Preview {
    ContentView()
}
