import SwiftUI
import AVKit

// 2. 教程 + 知识页
struct TutorialView: View {
    @ObservedObject var appState: AppState
    @State private var hasInteracted = false
    // 视频步骤默认展开（50/50），非视频步骤默认收起
    @State private var knowledgeExpanded = true
    // 非视频步骤的弹窗状态
    @State private var popupDismissed = false
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var isIPad: Bool { hSizeClass == .regular }
    var isVideoStep: Bool { appState.currentTutorialStep.videoName != nil }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                PaperBackground()

                HStack(spacing: 0) {
                    if knowledgeExpanded {
                        knowledgeArea
                            .frame(maxWidth: .infinity)
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        Rectangle()
                            .fill(LFColors.brown.opacity(0.15))
                            .frame(width: 1)
                    }
                    tutorialArea
                        .frame(maxWidth: .infinity)
                }

                // 非视频步骤弹窗
                if !isVideoStep && !popupDismissed {
                    tutorialHintPopup
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }

                // 底部左划跳过提示
                let step = appState.currentTutorialStep
                if step != .customizeBrush && step != .customizeFan && step != .assembleBones {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 13, weight: .medium))
                        Text("Swipe left to skip to the next step")
                            .font(.system(size: 13, design: .serif))
                    }
                    .foregroundColor(LFColors.brown.opacity(0.5))
                    .position(x: geo.size.width / 2, y: geo.size.height - (isIPad ? 28 : 18))
                }
            }
            .simultaneousGesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { val in
                        let step = appState.currentTutorialStep
                        let isCustomizeStep = step == .customizeBrush || step == .customizeFan
                        let isBonesStep = step == .assembleBones
                        if !isCustomizeStep && !isBonesStep && val.translation.width < -80 && abs(val.translation.height) < 80 {
                            nextStep()
                        }
                    }
            )
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: knowledgeExpanded)
        .onChange(of: appState.currentTutorialStep) { newStep in
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                knowledgeExpanded = newStep.videoName != nil
            }
            popupDismissed = false
            hasInteracted = false
        }
    }

    // MARK: - Popup (非视频步骤)
    var tutorialHintPopup: some View {
        ZStack {
            Color.black.opacity(0.28).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tutorial")
                            .font(.system(size: 11, weight: .semibold, design: .serif))
                            .foregroundColor(LFColors.gold)
                            .tracking(2).textCase(.uppercase)
                        Text(appState.currentTutorialStep.title)
                            .font(.system(size: 18, weight: .medium, design: .serif))
                            .foregroundColor(LFColors.brown)
                    }
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.35)) { popupDismissed = true }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(LFColors.brown)
                            .frame(width: 34, height: 34)
                            .background(Circle().fill(LFColors.brown.opacity(0.1)))
                    }
                }
                Text(appState.currentTutorialStep.description)
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(LFColors.ink)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(LFColors.paper.opacity(0.97))
                    .shadow(color: LFColors.brown.opacity(0.22), radius: 24, y: 6)
            )
            .padding(.horizontal, 44)
        }
    }

    // MARK: - Tutorial area
    var tutorialArea: some View {
        ZStack {
            VStack(spacing: 0) {
                // 顶部导航
                HStack {
                    if appState.currentTutorialStep.rawValue > 0 {
                        Button(action: prevStep) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: isIPad ? 20 : 17, weight: .medium))
                                .foregroundColor(LFColors.brown)
                                .frame(width: isIPad ? 54 : 44, height: isIPad ? 54 : 44)
                                .background(Circle().fill(LFColors.paper.opacity(0.9))
                                    .shadow(color: LFColors.brown.opacity(0.18), radius: 5))
                        }
                    } else {
                        Color.clear.frame(width: isIPad ? 54 : 44, height: isIPad ? 54 : 44)
                    }
                    Spacer()
                    HStack(spacing: isIPad ? 12 : 9) {
                        ForEach(TutorialStep.allCases, id: \.self) { step in
                            Circle()
                                .fill(step == appState.currentTutorialStep
                                      ? LFColors.brown : LFColors.brown.opacity(0.25))
                                .frame(width: step == appState.currentTutorialStep ? (isIPad ? 12 : 9) : (isIPad ? 8 : 6),
                                       height: step == appState.currentTutorialStep ? (isIPad ? 12 : 9) : (isIPad ? 8 : 6))
                                .animation(.spring(response: 0.3), value: appState.currentTutorialStep)
                        }
                    }
                    Spacer()
                    Color.clear.frame(width: isIPad ? 54 : 44, height: isIPad ? 54 : 44)
                }
                .padding(.horizontal, isIPad ? 32 : 24)
                .padding(.top, isIPad ? 24 : 20)

                // 交互演示区
                InteractiveDemoArea(
                    step: appState.currentTutorialStep,
                    hasInteracted: $hasInteracted,
                    onComplete: nextStep
                )
                .environmentObject(appState)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // 知识面板切换按钮（垂直居中，尺寸更轻量）
            VStack {
                Spacer()
                HStack {
                    Button(action: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                            knowledgeExpanded.toggle()
                        }
                    }) {
                        Image(systemName: knowledgeExpanded ? "chevron.left" : "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(LFColors.brown)
                            .frame(width: 30, height: 52)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(LFColors.paper.opacity(0.95))
                                    .shadow(color: LFColors.brown.opacity(0.2), radius: 4, x: 2, y: 0)
                            )
                    }
                    Spacer()
                }
                .padding(.leading, 4)
                Spacer()
            }

            // 弹窗关闭后左上角小提示徽章
            if !isVideoStep && popupDismissed {
                VStack {
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.35)) { popupDismissed = false }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 11))
                                Text(appState.currentTutorialStep.title)
                                    .font(.system(size: 11, design: .serif))
                                    .lineLimit(1)
                            }
                            .foregroundColor(LFColors.brown)
                            .padding(.horizontal, 11)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(LFColors.paper.opacity(0.93))
                                    .shadow(color: LFColors.brown.opacity(0.15), radius: 4)
                            )
                        }
                        Spacer()
                    }
                    .padding(.leading, 40)
                    .padding(.top, isIPad ? 110 : 100)
                    Spacer()
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
    }

    // MARK: - Knowledge area
    var knowledgeArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: isIPad ? 22 : 18) {
                HStack {
                    Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: isIPad ? 28 : 22, height: isIPad ? 28 : 22)
                    Text(appState.currentTutorialStep.knowledgeTitle)
                        .font(.system(size: isIPad ? 20 : 17, weight: .medium, design: .serif))
                        .foregroundColor(LFColors.brown)
                    Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: isIPad ? 28 : 22, height: isIPad ? 28 : 22)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, isIPad ? 36 : 28)

                if let img = UIImage(named: appState.currentTutorialStep.knowledgeImageName, in: .module, compatibleWith: nil) {
                    Image(uiImage: img)
                        .resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: isIPad ? 200 : 150)
                        .cornerRadius(10)
                        .padding(.horizontal, 16)
                } else {
                    Image("fan", bundle: .module).resizable().scaledToFit()
                        .frame(maxWidth: .infinity).frame(height: isIPad ? 200 : 150)
                        .padding(.horizontal, 16)
                }

                knowledgeSection(title: appState.currentTutorialStep.knowledgeTitle,
                                 body: appState.currentTutorialStep.knowledgeBody)

                // 教学提示区
                Divider().background(LFColors.brown.opacity(0.2)).padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Image(systemName: "hand.point.right.fill")
                            .font(.system(size: isIPad ? 16 : 13))
                            .foregroundColor(LFColors.gold)
                        Text("Tutorial")
                            .font(.system(size: isIPad ? 16 : 14, weight: .semibold, design: .serif))
                            .foregroundColor(LFColors.brown)
                            .tracking(1).textCase(.uppercase)
                    }
                    Text(appState.currentTutorialStep.description)
                        .font(.system(size: isIPad ? 17 : 15, design: .serif))
                        .foregroundColor(LFColors.ink.opacity(0.85))
                        .lineSpacing(5)
                }
            }
            .padding(.horizontal, isIPad ? 28 : 20)
            .padding(.bottom, 40)
        }
    }

    @ViewBuilder
    func knowledgeSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: isIPad ? 16 : 14, weight: .semibold, design: .serif))
                .foregroundColor(LFColors.brown)
                .tracking(1).textCase(.uppercase)
            Text(body)
                .font(.system(size: isIPad ? 17 : 15, design: .serif))
                .foregroundColor(LFColors.ink.opacity(0.85))
                .lineSpacing(5)
        }
    }

    func nextStep() {
        hasInteracted = false
        let all = TutorialStep.allCases
        if let idx = all.firstIndex(of: appState.currentTutorialStep), idx < all.count - 1 {
            appState.currentTutorialStep = all[idx + 1]
        } else {
            appState.currentPhase = .customization
        }
    }

    func prevStep() {
        hasInteracted = false
        let all = TutorialStep.allCases
        if let idx = all.firstIndex(of: appState.currentTutorialStep), idx > 0 {
            appState.currentTutorialStep = all[idx - 1]
        }
    }
}

// 无控件视频层（AVPlayerLayer 直接渲染，不显示进度条）
struct VideoPlayerLayer: UIViewRepresentable {
    let player: AVPlayer

    func makeUIView(context: Context) -> PlayerUIView {
        let v = PlayerUIView()
        v.player = player
        return v
    }
    func updateUIView(_ uiView: PlayerUIView, context: Context) {}

    class PlayerUIView: UIView {
        override class var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
        var player: AVPlayer? {
            get { playerLayer.player }
            set { playerLayer.player = newValue; playerLayer.videoGravity = .resizeAspectFill }
        }
    }
}

// 教程视频播放视图
struct TutorialVideoView: View {
    let videoName: String
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void
    @State private var player: AVPlayer? = nil
    @State private var isPlaying = false
    @State private var showNextButton = false
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width - 40, geo.size.height * 0.72, 460)
            VStack(spacing: 20) {
                Spacer()
                ZStack {
                    if let player = player {
                        VideoPlayerLayer(player: player)
                            .frame(width: side, height: side)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .overlay(RoundedRectangle(cornerRadius: 22)
                                .stroke(LFColors.brown.opacity(0.25), lineWidth: 1.5))
                            .shadow(color: LFColors.brown.opacity(0.18), radius: 12)
                    } else {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(LFColors.paper.opacity(0.5))
                            .frame(width: side, height: side)
                            .overlay(
                                Text("Video unavailable")
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundColor(LFColors.brown.opacity(0.45))
                            )
                    }

                    // 点击播放覆盖层（无按钮，点击任意位置播放）
                    if !isPlaying && player != nil {
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.black.opacity(0.28))
                            .frame(width: side, height: side)
                            .overlay(
                                VStack(spacing: 10) {
                                    Image(systemName: "hand.tap.fill")
                                        .font(.system(size: isIPad ? 32 : 26))
                                        .foregroundColor(.white.opacity(0.85))
                                    Text("Tap to play")
                                        .font(.system(size: isIPad ? 15 : 13, design: .serif))
                                        .foregroundColor(.white.opacity(0.75))
                                }
                            )
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity)
                .onTapGesture {
                    if !isPlaying && player != nil { startPlaying() }
                }

                if showNextButton {
                    Button(action: onComplete) {
                        HStack(spacing: 8) {
                            Text("Next Step")
                                .font(.system(size: isIPad ? 18 : 15, weight: .medium, design: .serif))
                                .tracking(1)
                            Image(systemName: "arrow.right")
                                .font(.system(size: isIPad ? 16 : 13, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, isIPad ? 44 : 32)
                        .padding(.vertical, isIPad ? 16 : 13)
                        .background(
                            Group {
                                if let uiImg = UIImage(named: "Union1", in: .module, compatibleWith: nil) {
                                    Image(uiImage: uiImg).resizable().scaledToFill()
                                } else { LFColors.brown }
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: isIPad ? 13 : 10))
                        .shadow(color: LFColors.brown.opacity(0.35), radius: 8, y: 3)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: showNextButton)
            .animation(.easeInOut(duration: 0.25), value: isPlaying)
        }
        .onAppear { setupPlayer() }
        .onDisappear { player?.pause() }
    }

    private func startPlaying() {
        guard let p = player else { return }
        withAnimation { isPlaying = true }
        p.play()
        hasInteracted = true
    }

    private func setupPlayer() {
        let url = Bundle.main.url(forResource: videoName, withExtension: "mp4")
            ?? Bundle.main.url(forResource: "Resources/\(videoName)", withExtension: "mp4")
        guard let url = url else { return }
        let p = AVPlayer(url: url)
        player = p
        // 不自动播放，等用户点击
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: p.currentItem, queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                withAnimation { showNextButton = true }
                p.seek(to: .zero)
                p.play()
            }
        }
    }
}

// 交互演示区域
struct InteractiveDemoArea: View {
    let step: TutorialStep
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch step {
            case .scrapeLacquer, .addWater, .addPaint, .stirAndDip:
                TutorialVideoView(
                    videoName: step.videoName!,
                    hasInteracted: $hasInteracted,
                    onComplete: onComplete
                )
                .id(step)
            case .assembleBones:
                FanBoneAssemblyView(hasInteracted: $hasInteracted, onComplete: onComplete)
            case .customizeBrush:
                CustomizeBrushStepView(hasInteracted: $hasInteracted, onComplete: onComplete)
            case .customizeFan:
                InteractiveToolView(hasInteracted: $hasInteracted, onComplete: onComplete)
                    .environmentObject(appState)
            }
        }
    }
}
