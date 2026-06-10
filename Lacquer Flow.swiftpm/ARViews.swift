import SwiftUI
import Photos
import RealityKit

// MARK: - AR UI Views

// 5. 扫描提示
struct ScanInstructionView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        VStack {
            // Traditional style instruction card
            VStack(spacing: 12) {
                Image("cloud", bundle: .module)
                    .resizable().scaledToFit().frame(width: 28, height: 28)

                Text("Find a Surface")
                    .font(.system(size: 16, weight: .medium, design: .serif))
                    .foregroundColor(LFColors.brown)

                Text("Move your device slowly to scan.\nTap to place the water basin.")
                    .font(.system(size: 15, design: .serif))
                    .foregroundColor(LFColors.ink.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                if !appState.handStatus.isEmpty {
                    Text(appState.handStatus)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(LFColors.lightBrown)
                        .padding(.top, 2)
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(LFColors.paper.opacity(0.92))
                    .overlay(RoundedRectangle(cornerRadius: 14)
                        .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
            )
            .padding(.top, 56)
            .padding(.horizontal, 32)

            Spacer()
        }
    }
}

// 4. 创作控制
struct CreationControlView: View {
    @ObservedObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        VStack {
            HStack {
                Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: isIPad ? 22 : 18, height: isIPad ? 22 : 18)
                Text("Tap the water to drop lacquer")
                    .font(.system(size: isIPad ? 16 : 13, design: .serif))
                    .foregroundColor(LFColors.brown)
                Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: isIPad ? 22 : 18, height: isIPad ? 22 : 18)
            }
            .padding(.horizontal, isIPad ? 28 : 20)
            .padding(.vertical, isIPad ? 16 : 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LFColors.paper.opacity(0.92))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                    .shadow(color: .black.opacity(0.1), radius: 8)
            )
            .padding(.top, 52)

            Spacer()

            VStack(spacing: 10) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isIPad ? 16 : 12) {
                        ForEach(AppColors.palettes, id: \.self) { color in
                            Circle()
                                .fill(Color(uiColor: color))
                                .frame(width: isIPad ? 56 : 44, height: isIPad ? 56 : 44)
                                .overlay(Circle().stroke(LFColors.paper, lineWidth: appState.selectedColor == color ? 3 : 0))
                                .overlay(Circle().stroke(LFColors.brown.opacity(0.3), lineWidth: 1))
                                .shadow(color: .black.opacity(0.15), radius: 4)
                                .scaleEffect(appState.selectedColor == color ? 1.12 : 1.0)
                                .animation(.spring(response: 0.25), value: appState.selectedColor == color)
                                .onTapGesture { appState.selectedColor = color }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(LFColors.paper.opacity(0.88))
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(LFColors.brown.opacity(0.15), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )
                .padding(.horizontal, 24)

                LFButton(title: "Finish Painting") {
                    appState.currentPhase = .transfer
                }
                .padding(.bottom, 28)
            }
        }
    }
}

// 5. 转印过程
struct TransferView: View {
    @ObservedObject var appState: AppState
    @State private var isDipping = false
    @State private var arrowPulse = false

    var body: some View {
        ZStack {
            // 全屏手势区域
            Color.clear
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 40)
                        .onEnded { val in
                            guard !isDipping,
                                  val.translation.height > 40,
                                  abs(val.translation.width) < 80 else { return }
                            isDipping = true
                            appState.userTriggeredDip = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) {
                                isDipping = false
                            }
                        }
                )

            VStack {
                VStack(spacing: 8) {
                    Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 22, height: 22)
                    Text(isDipping ? "Dyeing the fan..." : "Fan is ready — swipe down to dip")
                        .font(.system(size: 15, design: .serif))
                        .foregroundColor(LFColors.brown)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LFColors.paper.opacity(0.92))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                )
                .padding(.top, 52)

                Spacer()

                if !isDipping {
                    VStack(spacing: 6) {
                        Image(systemName: "hand.point.down.fill")
                            .font(.system(size: 24))
                            .foregroundColor(LFColors.brown.opacity(0.75))
                        ZStack {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundColor(LFColors.brown.opacity(0.75))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundColor(LFColors.brown.opacity(0.4))
                                .offset(y: 8)
                        }
                        .offset(y: arrowPulse ? 4 : -2)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: arrowPulse)
                    }
                    .padding(.bottom, 48)
                }
            }
            .onAppear {
                DispatchQueue.main.async {
                    arrowPulse = true
                }
            }
        }
    }
}

// 6. 手势魔法（AR 阶段 UI）
struct HandMagicOverlay: View {
    @ObservedObject var appState: AppState
    @State private var saveStatus: String = ""
    @State private var showSaveOptions = false
    @State private var isSaving = false

    var body: some View {
        VStack {
            VStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
                    Text("Hand Control")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundColor(LFColors.brown)
                    Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
                }
                Text(appState.handStatus)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(LFColors.ink.opacity(0.7))
                if !saveStatus.isEmpty {
                    Text(saveStatus)
                        .font(.system(size: 14, design: .serif))
                        .foregroundColor(LFColors.lightBrown)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(LFColors.paper.opacity(0.92))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                    .shadow(color: .black.opacity(0.1), radius: 8)
            )
            .padding(.top, 52)

            Spacer()

            VStack(spacing: 14) {
                if appState.fanCustomization.fanShape == .round {
                    HStack(spacing: 20) {
                        gestureHint(icon: "hand.raised.fingers.spread", text: "Open hand — fan follows")
                        gestureHint(icon: "hand.raised", text: "Fist to hold in place")
                    }
                } else {
                    HStack(spacing: 20) {
                        gestureHint(icon: "hand.raised.fingers.spread", text: "Open hand — fan spreads")
                        gestureHint(icon: "hand.pinch", text: "Pinch — fan closes")
                    }
                }

                HStack(spacing: 14) {
                    LFButton(title: isSaving ? "Saving..." : "Save to Photos", action: {
                        showSaveOptions = true
                    }, style: .accent)
                    .disabled(isSaving)
                    .opacity(isSaving ? 0.6 : 1.0)

                    LFButton(title: "Finish") { appState.currentPhase = .outro }
                }
            }
            .padding(.bottom, 32)
        }
        .alert("Save Your Fan", isPresented: $showSaveOptions) {
            Button("Save to Photos") { saveToPhotoAlbum() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Save your custom fan to your photo album?")
        }
    }

    @ViewBuilder
    func gestureHint(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14)).foregroundColor(LFColors.brown.opacity(0.7))
            Text(text).font(.system(size: 14, design: .serif)).foregroundColor(LFColors.ink.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(LFColors.paper.opacity(0.85))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(LFColors.brown.opacity(0.15), lineWidth: 1))
        )
    }

    func saveToPhotoAlbum() {
        isSaving = true

        // 先检查当前权限状态
        let currentStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch currentStatus {
        case .authorized, .limited:
            // 已有权限，直接保存
            saveStatus = "Capturing image..."
            captureAndSave()

        case .notDetermined:
            // 首次请求权限
            saveStatus = "Requesting permission..."
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    if status == .authorized || status == .limited {
                        self.saveStatus = "Capturing image..."
                        self.captureAndSave()
                    } else {
                        self.saveStatus = "Permission denied - check Settings"
                        self.isSaving = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            self.saveStatus = ""
                        }
                    }
                }
            }

        case .denied, .restricted:
            // 权限被拒绝，提示用户去设置
            saveStatus = "Permission denied - open Settings to allow photo access"
            isSaving = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.saveStatus = ""
            }

        @unknown default:
            saveStatus = "Unknown permission status"
            isSaving = false
        }
    }

    func captureAndSave() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let arView = findARView(in: window) else {
            saveStatus = "Failed to find AR view"
            isSaving = false
            return
        }

        // 添加超时保护
        var hasCompleted = false
        let timeoutWorkItem = DispatchWorkItem {
            if !hasCompleted {
                DispatchQueue.main.async {
                    self.saveStatus = "Capture timeout - please try again"
                    self.isSaving = false
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: timeoutWorkItem)

        arView.snapshot(saveToHDR: false) { image in
            hasCompleted = true
            timeoutWorkItem.cancel()

            guard let image = image else {
                DispatchQueue.main.async {
                    self.saveStatus = "Failed to capture image"
                    self.isSaving = false
                }
                return
            }

            DispatchQueue.main.async {
                self.saveStatus = "Saving to Photos..."
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        self.saveStatus = "Saved to Photos!"
                    } else {
                        self.saveStatus = "Save failed: \(error?.localizedDescription ?? "Unknown error")"
                    }
                    self.isSaving = false

                    // 3秒后清除状态消息
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        self.saveStatus = ""
                    }
                }
            }
        }
    }

    func findARView(in view: UIView) -> ARView? {
        if let arView = view as? ARView { return arView }
        for subview in view.subviews { if let arView = findARView(in: subview) { return arView } }
        return nil
    }
}

// 7. 2D 展示页
struct OutroView: View {
    @ObservedObject var appState: AppState
    @State private var appear = false
    @State private var artAppear = false
    
    var handleColor: Color {
        switch appState.fanCustomization.handleStyle {
        case .classic: return Color(red: 0.40, green: 0.20, blue: 0.10)
        case .elegant: return Color(red: 0.60, green: 0.40, blue: 0.20)
        case .modern:  return Color.gray
        }
    }
    
    var body: some View {
        ZStack {
            PaperBackground()
            VStack(spacing: 0) {
                outroHeader
                Spacer()
                outroFanCard
                Spacer()
                outroButtons
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.75).delay(0.15)) { appear = true }
            withAnimation(.easeOut(duration: 1.2).delay(0.5)) { artAppear = true }
        }
    }
    
    private var outroHeader: some View {
        HStack {
            Spacer()
            HStack(spacing: 6) {
                Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
                Text("Your Fan")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(LFColors.brown)
                    .tracking(2)
                Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
            }
            Spacer()
        }
        .padding(.top, 28)
    }
    
    private var outroFanCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LFColors.paper.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: 20)
                    .stroke(LFColors.brown.opacity(0.15), lineWidth: 1))
                .frame(maxWidth: 480, maxHeight: 340)
                .shadow(color: LFColors.brown.opacity(0.1), radius: 16)
            VStack(spacing: 8) {
                outroFanContent
                    .scaleEffect(appear ? 1.0 : 0.8)
                    .opacity(appear ? 1.0 : 0)
                Text("Every flow is unique")
                    .font(.system(size: 13, weight: .light, design: .serif))
                    .foregroundColor(LFColors.brown.opacity(0.55))
                    .tracking(1).italic()
                    .opacity(appear ? 1.0 : 0)
            }
        }
        .padding(.horizontal, 32)
    }
    
    private var outroFanContent: some View {
        let fanW: CGFloat = 220
        let fillColor = appState.fanCustomization.fanColor.tintColor
        let strokeColor = LFColors.brown.opacity(0.12)
        
        return ZStack {
            // 扇面底色
            switch appState.fanCustomization.fanShape {
            case .folding:
                FanPreviewShape()
                    .fill(fillColor)
                    .frame(width: fanW, height: fanW)
                    .shadow(color: LFColors.brown.opacity(0.12), radius: 12)
            case .round:
                Circle()
                    .fill(fillColor)
                    .frame(width: fanW, height: fanW)
                    .shadow(color: LFColors.brown.opacity(0.12), radius: 12)
            }
            
            // 漆流艺术晕染层（基于用户选色）
            outroMarbleLayer
            
            // 用户手绘图案
            outroPatternLayer
            
            // 自定义文字（限制在扇面内）
            outroTextLayer
            
            // 扇柄
            outroHandle
        }
    }
    
    // 漆流艺术晕染效果：用用户实际滴入的颜色，在扇面形状内做柔和渐变
    @ViewBuilder
    private var outroMarbleLayer: some View {
        // 只有用户滴入了颜色才显示渐变效果
        if !appState.droppedColors.isEmpty {
            let palette = Array(appState.droppedColors.prefix(6))
            let extended = palette + [palette.first!]
            let fanW: CGFloat = 220

            switch appState.fanCustomization.fanShape {
            case .round:
                Circle()
                    .fill(
                        AngularGradient(
                            gradient: Gradient(colors: extended),
                            center: .center
                        )
                    )
                    .frame(width: fanW, height: fanW)
                    .blur(radius: 10)
                    .opacity(0.85)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.12), lineWidth: 2)
                            .blur(radius: 3)
                    )
                    .clipShape(Circle())  // 确保不溢出
                    .opacity(artAppear ? 1.0 : 0)

            case .folding:
                ZStack {
                    FanPreviewShape()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: extended),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fanW, height: fanW)
                        .blur(radius: 8)
                        .opacity(0.75)

                    // 沿扇骨方向的几条柔和高光，让流向更像扇形纹路
                    ForEach(0..<7, id: \.self) { i in
                        FanPreviewShape()
                            .stroke(
                                Color.white.opacity(0.10),
                                style: StrokeStyle(lineWidth: 2, lineCap: .round)
                            )
                            .frame(width: fanW, height: fanW)
                            .rotationEffect(.degrees(Double(i - 3) * 5))
                            .blur(radius: 3)
                    }
                }
                .clipShape(FanPreviewShape())  // 确保不溢出
                .opacity(artAppear ? 1.0 : 0)
            }
        }
    }
    
    private var outroHandle: some View {
        let width: CGFloat
        let radius: CGFloat
        switch appState.fanCustomization.handleStyle {
        case .classic: width = 16; radius = 3
        case .elegant: width = 12; radius = 8
        case .modern:  width = 8;  radius = 2
        }
        return RoundedRectangle(cornerRadius: radius)
            .fill(LinearGradient(colors: [handleColor, handleColor.opacity(0.7)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: width, height: 56)
            .offset(y: 126)
            .shadow(color: handleColor.opacity(0.3), radius: 4)
    }
    
    @ViewBuilder
    private var outroPatternLayer: some View {
        if !appState.userDrawnPattern.isEmpty {
            let canvas = Canvas { context, _ in
                for pathPoints in appState.userDrawnPattern {
                    guard pathPoints.count > 1 else { continue }
                    var path = Path()
                    let scaled = pathPoints.map { CGPoint(x: $0.x * 0.2 + 44, y: $0.y * 0.2 + 22) }
                    path.move(to: scaled[0])
                    for pt in scaled.dropFirst() { path.addLine(to: pt) }
                    context.stroke(path, with: .color(LFColors.brown.opacity(0.55)),
                                   style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }
                .frame(width: 220, height: 220)
            
            switch appState.fanCustomization.fanShape {
            case .folding: canvas.clipShape(FanPreviewShape())
            case .round:   canvas.clipShape(Circle())
            }
        }
    }
    
    // 自定义文字：限制在扇面中央区域，不超出
    @ViewBuilder
    private var outroTextLayer: some View {
        let text = appState.fanCustomization.customText
        if !text.isEmpty && appState.fanCustomization.textPlacement == .surface {
            // 主色取第一个滴入颜色，否则用棕色
            let textColor: Color = appState.droppedColors.first.map { c in
                // 加深一点以保证可读性
                c.opacity(0.85)
            } ?? LFColors.brown.opacity(0.75)
            
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            // 限制宽度在扇面内（折扇有效宽约 140pt，圆扇约 160pt）
                .frame(maxWidth: appState.fanCustomization.fanShape == .folding ? 130 : 155)
                .offset(y: appState.fanCustomization.fanShape == .folding ? -30 : 0)
        }
    }
    
    private var outroButtons: some View {
        LFButton(title: "Start Over", action: {
            appState.reset()
            withAnimation(.easeInOut(duration: 0.4)) {
                // 直接回到教程里的”扇骨拼装”步骤
                appState.currentPhase = .tutorial
                appState.currentTutorialStep = .assembleBones
            }
        }, style: .primary)
        .padding(.bottom, 36)
    }
}
