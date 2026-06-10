import SwiftUI

// MARK: - 2. 主入口视图
struct ContentView: View {
    @StateObject var appState = AppState()
    @StateObject private var musicPlayer = BackgroundMusicPlayer.shared

    var body: some View {
        ZStack {
            // 背景层
            Color.black.ignoresSafeArea()

            // 核心 AR 视图 (仅在 AR 相关阶段显示)
            if [.arScan, .creation, .transfer, .handMagic].contains(appState.currentPhase) {
                ARCreativeContainer(appState: appState)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }

            // UI 覆盖层
            VStack {
                switch appState.currentPhase {
                case .intro:
                    IntroAnimationView(appState: appState)
                case .tutorial:
                    TutorialView(appState: appState)
                case .customization:
                    CustomizationView(appState: appState)
                case .arScan:
                    ScanInstructionView(appState: appState)
                case .creation:
                    CreationControlView(appState: appState)
                case .transfer:
                    TransferView(appState: appState)
                case .handMagic:
                    HandMagicOverlay(appState: appState)
                case .outro:
                    OutroView(appState: appState)
                }
            }

            // 全局静音按钮（右上角悬浮）
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        musicPlayer.toggleMute()
                    }) {
                        Image(systemName: musicPlayer.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(LFColors.brown)
                            .frame(width: 34, height: 34)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.9))
                                    .shadow(color: .black.opacity(0.2), radius: 4)
                            )
                    }
                    .padding(.trailing, 20)
                }
                .padding(.top, 18)
                Spacer()
            }
        }
        .animation(.easeInOut, value: appState.currentPhase)
        .onAppear {
            // 启动背景音乐
            musicPlayer.playBackgroundMusic()
        }
        .onDisappear {
            // 停止背景音乐
            musicPlayer.stopMusic()
        }
    }
}
