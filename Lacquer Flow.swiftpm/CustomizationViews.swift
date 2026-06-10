import SwiftUI

// MARK: - Customization Views

// 3. 自定义视图（定制预览 + 自定义选择）
struct CustomizationView: View {
    @ObservedObject var appState: AppState
    @State private var showSelection = false

    var body: some View {
        if showSelection {
            CustomizationSelectionView(appState: appState, onBack: {
                withAnimation(.easeInOut(duration: 0.35)) { showSelection = false }
            })
            .transition(.move(edge: .trailing).combined(with: .opacity))
        } else {
            CustomizationPreviewView(appState: appState, onSkip: {
                appState.currentPhase = .arScan
            }, onConfirm: {
                withAnimation(.easeInOut(duration: 0.35)) { showSelection = true }
            })
            .transition(.opacity)
        }
    }
}

// 定制预览页
struct CustomizationPreviewView: View {
    @ObservedObject var appState: AppState
    let onSkip: () -> Void
    let onConfirm: () -> Void
    @State private var appear = false

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
                previewHeader
                Spacer()
                fanCard
                Spacer()
                HStack(spacing: 20) {
                    LFButton(title: "Skip", action: onSkip, style: .secondary)
                    LFButton(title: "Customize", action: onConfirm)
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                appear = true
            }
        }
    }

    private var previewHeader: some View {
        HStack {
            Button(action: { appState.currentPhase = .tutorial }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(LFColors.brown)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(LFColors.paper.opacity(0.8))
                        .shadow(color: LFColors.brown.opacity(0.15), radius: 4))
            }
            Spacer()
            HStack(spacing: 6) {
                Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
                Text("Preview")
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundColor(LFColors.brown)
                    .tracking(2)
                Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
            }
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    private var fanCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LFColors.paper.opacity(0.6))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                .frame(maxWidth: 520, maxHeight: 320)
                .shadow(color: LFColors.brown.opacity(0.1), radius: 12)
            fanPreviewContent
                .scaleEffect(appear ? 1.0 : 0.85)
                .opacity(appear ? 1.0 : 0)
        }
        .padding(.horizontal, 32)
    }

    private var fanPreviewContent: some View {
        // 扇柄宽度保持一致，只通过圆角等形态区分风格
        let handleW: CGFloat = 12
        let handleR: CGFloat
        switch appState.fanCustomization.handleStyle {
        case .classic: handleR = 3
        case .elegant: handleR = 8
        case .modern:  handleR = 2
        }
        return ZStack {
            FanPreviewShape()
                .fill(Color.white)
                .frame(width: 200, height: 200)
                .overlay(FanPreviewShape().stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                .shadow(color: LFColors.brown.opacity(0.1), radius: 8)
            drawnPatternLayer
            fanRibs
            RoundedRectangle(cornerRadius: handleR)
                .fill(LinearGradient(colors: [handleColor, handleColor.opacity(0.7)],
                                     startPoint: .top, endPoint: .bottom))
                .frame(width: handleW, height: 52)
                .offset(y: 116)
                .shadow(color: LFColors.brown.opacity(0.2), radius: 4)
        }
    }

    @ViewBuilder
    private var drawnPatternLayer: some View {
        if !appState.userDrawnPattern.isEmpty {
            Canvas { context, _ in
                for pathPoints in appState.userDrawnPattern {
                    guard pathPoints.count > 1 else { continue }
                    var path = Path()
                    let scaled = pathPoints.map { CGPoint(x: $0.x * 0.18 + 40, y: $0.y * 0.18 + 20) }
                    path.move(to: scaled[0])
                    for pt in scaled.dropFirst() { path.addLine(to: pt) }
                    context.stroke(path, with: .color(LFColors.brown.opacity(0.6)),
                                   style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(width: 200, height: 200)
            .clipShape(FanPreviewShape())
        }
    }

    private var fanRibs: some View {
        ForEach(0..<7, id: \.self) { i in
            Path { path in
                let center = CGPoint(x: 100, y: 200)
                let angle = 380.0 + (Double(i) / 6.0) * 140.0
                let ex = center.x + CGFloat(cos(angle * .pi / 180) * 100)
                let ey = center.y - CGFloat(sin(angle * .pi / 180) * 100)
                path.move(to: center)
                path.addLine(to: CGPoint(x: ex, y: ey))
            }
            .stroke(LFColors.brown.opacity(0.25), lineWidth: 1.5)
            .frame(width: 200, height: 200)
        }
    }
}

// 自定义选择页
struct CustomizationSelectionView: View {
    @ObservedObject var appState: AppState
    let onBack: () -> Void
    @State private var selectedTab = 0
    @State private var appear = false

    let tabs = ["Fan Shape", "Handle", "Color"]

    var body: some View {
        ZStack {
            PaperBackground()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(LFColors.brown)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(LFColors.paper.opacity(0.8))
                                .shadow(color: LFColors.brown.opacity(0.15), radius: 4))
                    }
                    Spacer()
                    HStack(spacing: 6) {
                        Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
                        Text("Customize")
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundColor(LFColors.brown)
                            .tracking(2)
                        Image("cloud", bundle: .module).resizable().scaledToFit().frame(width: 18, height: 18)
                    }
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)

                // Fan preview (center, updates in real time)
                FanPreviewWithCustomization(appState: appState)
                    .scaleEffect(appear ? 1.0 : 0.85)
                    .opacity(appear ? 1.0 : 0)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)

                // Tab bar
                HStack(spacing: 0) {
                    ForEach(tabs.indices, id: \.self) { i in
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) { selectedTab = i }
                        }) {
                            VStack(spacing: 4) {
                                Text(tabs[i])
                                    .font(.system(size: 13, design: .serif))
                                    .foregroundColor(selectedTab == i ? LFColors.brown : LFColors.brown.opacity(0.45))
                                Rectangle()
                                    .fill(selectedTab == i ? LFColors.brown : Color.clear)
                                    .frame(height: 1.5)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .overlay(Divider().offset(y: 16), alignment: .bottom)

                // Options
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        if selectedTab == 0 {
                            fanShapeOptions
                        } else if selectedTab == 1 {
                            handleOptions
                        } else {
                            colorOptions
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.vertical, 20)
                }

                Spacer()

                LFButton(title: "Confirm") {
                    appState.currentPhase = .arScan
                }
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) { appear = true }
        }
    }

    // Fan shape options
    var fanShapeOptions: some View {
        ForEach(FanShape.allCases) { shape in
            OptionChip(
                label: shape.rawValue,
                isSelected: appState.fanCustomization.fanShape == shape
            ) {
                withAnimation(.spring(response: 0.3)) {
                    appState.fanCustomization.fanShape = shape
                }
            }
        }
    }

    // Handle options
    var handleOptions: some View {
        ForEach(HandleStyle.allCases) { style in
            OptionChip(
                label: style.rawValue,
                isSelected: appState.fanCustomization.handleStyle == style,
                color: handleColor(for: style)
            ) {
                withAnimation(.spring(response: 0.3)) {
                    appState.fanCustomization.handleStyle = style
                }
            }
        }
    }

    // Color options
    var colorOptions: some View {
        ForEach(FanColor.allCases) { fanColor in
            OptionChip(
                label: fanColor.rawValue,
                isSelected: appState.fanCustomization.fanColor == fanColor,
                color: fanColor.displayColor
            ) {
                withAnimation(.spring(response: 0.3)) {
                    appState.fanCustomization.fanColor = fanColor
                }
            }
        }
    }

    func handleColor(for style: HandleStyle) -> Color {
        switch style {
        case .classic: return Color(red: 0.40, green: 0.20, blue: 0.10)
        case .elegant: return Color(red: 0.60, green: 0.40, blue: 0.20)
        case .modern:  return Color.gray
        }
    }
}

// Option chip component
struct OptionChip: View {
    let label: String
    let isSelected: Bool
    var color: Color = LFColors.brown
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isSelected ? Color.white.opacity(0.85) : color)
                    .frame(width: 14, height: 14)
                    .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 1))
                Text(label)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(isSelected ? .white : LFColors.brown)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(chipBackground)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.spring(response: 0.25), value: isSelected)
        }
    }

    @ViewBuilder
    private var chipBackground: some View {
        if isSelected {
            if let uiImg = UIImage(named: "Union1", in: .module, compatibleWith: nil) {
                Image(uiImage: uiImg).resizable().scaledToFill()
            } else {
                LFColors.brown
            }
        } else {
            RoundedRectangle(cornerRadius: 10)
                .fill(LFColors.paper.opacity(0.8))
                .overlay(RoundedRectangle(cornerRadius: 10)
                    .stroke(LFColors.brown.opacity(0.3), lineWidth: 1))
        }
    }
}

// Fan preview with real-time customization
struct FanPreviewWithCustomization: View {
    @ObservedObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var hSizeClass
    private var isIPad: Bool { hSizeClass == .regular }

    private var handleColor: Color {
        switch appState.fanCustomization.handleStyle {
        case .classic: return Color(red: 0.40, green: 0.20, blue: 0.10)
        case .elegant: return Color(red: 0.72, green: 0.52, blue: 0.30)
        case .modern:  return Color(white: 0.45)
        }
    }

    // 不同样式的扇柄形状参数
    private var handleWidth: CGFloat {
        // 三种扇柄风格在 3D 预览中保持相同粗细，仅颜色 / 圆角变化
        return isIPad ? 11 : 8
    }
    private var handleRadius: CGFloat {
        switch appState.fanCustomization.handleStyle {
        case .classic: return 3   // 竹节感，小圆角
        case .elegant: return 8   // 圆润
        case .modern:  return 2   // 方正
        }
    }

    var body: some View {
        let fanW: CGFloat = isIPad ? 180 : 130
        let handleH: CGFloat = isIPad ? 52 : 38
        let fillColor = appState.fanCustomization.fanColor.tintColor
        let strokeColor = LFColors.brown.opacity(0.25)

        ZStack {
            // 扇柄（在扇面下方，稍微叠入扇面底部）
            RoundedRectangle(cornerRadius: handleRadius)
                .fill(LinearGradient(
                    colors: [handleColor.opacity(0.9), handleColor],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: handleWidth, height: handleH)
                .shadow(color: handleColor.opacity(0.35), radius: 4, x: 1, y: 2)
                .offset(y: fanW * 0.5 + handleH * 0.38)

            // 扇面
            switch appState.fanCustomization.fanShape {
            case .folding:
                FanPreviewShape()
                    .fill(fillColor)
                    .frame(width: fanW, height: fanW)
                    .overlay(FanPreviewShape().stroke(strokeColor, lineWidth: 1))
                    .shadow(color: LFColors.brown.opacity(0.12), radius: 6)
            case .round:
                Circle()
                    .fill(fillColor)
                    .frame(width: fanW, height: fanW)
                    .overlay(Circle().stroke(strokeColor, lineWidth: 1))
                    .shadow(color: LFColors.brown.opacity(0.12), radius: 6)
            }
        }
        .frame(width: fanW, height: fanW + handleH)
    }
}


// 扇子预览形状（折扇）
struct FanPreviewShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.maxY)
        let radius = min(rect.width, rect.height)
        path.addArc(center: center, radius: radius, startAngle: .degrees(200), endAngle: .degrees(340), clockwise: false)
        path.addLine(to: center)
        path.closeSubpath()
        return path
    }
}
