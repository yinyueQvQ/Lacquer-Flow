import SwiftUI

// MARK: - Tutorial Interactive Views

// 第一面：刮漆
struct ScrapeLacquerView: View {
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void
    @State private var scrapeProgress: CGFloat = 0
    @State private var scrapePoints: [CGPoint] = []
    @State private var isDone = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LFColors.paper.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                .shadow(color: LFColors.brown.opacity(0.1), radius: 10)

            VStack(spacing: 12) {
                // 漆树图（用 group6 或 lacquerflow）
                ZStack {
                    if let img = UIImage(named: "group6", in: .module, compatibleWith: nil) {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(height: 130).cornerRadius(10)
                    } else {
                        Image("lacquerflow", bundle: .module)
                            .resizable().scaledToFit()
                            .frame(height: 130).cornerRadius(10)
                    }
                    // 刮漆轨迹
                    Canvas { ctx, _ in
                        for pt in scrapePoints.dropLast() {
                            let idx = scrapePoints.firstIndex(of: pt) ?? 0
                            if idx + 1 < scrapePoints.count {
                                var path = Path()
                                path.move(to: pt)
                                path.addLine(to: scrapePoints[idx + 1])
                                ctx.stroke(path, with: .color(Color(red: 0.85, green: 0.75, blue: 0.4).opacity(0.7)),
                                           style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            }
                        }
                    }
                    .frame(height: 130)
                    .cornerRadius(10)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            scrapePoints.append(val.location)
                            if scrapePoints.count > 80 { scrapePoints.removeFirst() }
                            let progress = min(CGFloat(scrapePoints.count) / 60.0, 1.0)
                            scrapeProgress = progress
                            hasInteracted = true
                            if progress >= 1.0 && !isDone {
                                isDone = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onComplete() }
                            }
                        }
                    )
                }

                // 进度条
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LFColors.brown.opacity(0.15))
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LFColors.brown.opacity(0.6))
                            .frame(width: g.size.width * scrapeProgress)
                    }
                }
                .frame(height: 6)
                .padding(.horizontal, 20)

                Text(scrapeProgress < 1.0 ? "Swipe to scrape lacquer" : "Lacquer collected!")
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(LFColors.brown.opacity(0.6))
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity).frame(height: 240)
        .padding(.horizontal, 28)
    }
}

// 第二面：扇骨拼装（拖拽5根扇骨到辅助线）
struct FanBoneAssemblyView: View {
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void

    @State private var boneSnapped: [Bool] = Array(repeating: false, count: 5)
    @State private var dragOffsets: [CGSize] = Array(repeating: .zero, count: 5)

    let snapAngles: [Double] = [-55, -27.5, 0, 27.5, 55]
    let boneLength: CGFloat = 185          // 随辅助线等比放大（140 × 1.33）
    var boneDragLength: CGFloat { boneLength }

    var snappedCount: Int { boneSnapped.filter { $0 }.count }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let cx = w / 2
            let cy = h * 0.38
            let pivot = CGPoint(x: cx, y: cy + 100)
            // 容器：更靠右上
            let contX = w - 95
            let contY = h - 250

            ZStack {
                // 扇形辅助线轮廓
                FanPreviewShape()
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundColor(LFColors.brown.opacity(0.30))
                    .frame(width: 400, height: 320)
                    .position(x: cx, y: cy)

                // 吸附点指示（未吸附时显示金色圆点，放大到 20pt）
                ForEach(0..<5) { i in
                    if !boneSnapped[i] {
                        Circle()
                            .fill(LFColors.gold.opacity(0.45))
                            .frame(width: 20, height: 20)
                            .position(snapPoint(i: i, pivot: pivot))
                    }
                }

                // 已吸附的扇骨（从 pivot 画到 snapPoint）
                ForEach(0..<5) { i in
                    if boneSnapped[i] {
                        let sp = snapPoint(i: i, pivot: pivot)
                        Path { p in
                            p.move(to: pivot)
                            p.addLine(to: sp)
                        }
                        .stroke(LinearGradient(
                            colors: [LFColors.brown, LFColors.lightBrown],
                            startPoint: .bottom, endPoint: .top), lineWidth: 6)
                    }
                }

                // brushtube 容器（放大到 95×120）
                ZStack(alignment: .bottom) {
                    // 未吸附的骨在图片下层，只露出上半截
                    ForEach(0..<5) { i in
                        if !boneSnapped[i] {
                            let offsetX = CGFloat(i - 2) * 27
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(
                                    colors: [LFColors.brown, LFColors.lightBrown],
                                    startPoint: .top, endPoint: .bottom))
                                .frame(width: 14, height: boneDragLength)
                                .offset(x: offsetX, y: -(180 - boneDragLength / 2))
                                .offset(dragOffsets[i])
                                .gesture(DragGesture()
                                    .onChanged { val in
                                        dragOffsets[i] = val.translation
                                        hasInteracted = true
                                    }
                                    .onEnded { val in
                                        let boneTopX = contX + offsetX + val.translation.width
                                        let boneTopY = contY - (180 - boneDragLength / 2) - boneDragLength / 2 + val.translation.height
                                        var snapped = false
                                        for j in 0..<5 {
                                            if boneSnapped[j] { continue }
                                            let sp = snapPoint(i: j, pivot: pivot)
                                            if hypot(boneTopX - sp.x, boneTopY - sp.y) < 90 {
                                                withAnimation(.spring(response: 0.3)) { boneSnapped[j] = true }
                                                snapped = true
                                                break
                                            }
                                        }
                                        withAnimation(.spring(response: 0.4)) { dragOffsets[i] = .zero }
                                        if snapped {
                                            DispatchQueue.main.async {
                                                if boneSnapped.filter({ $0 }).count >= 5 {
                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onComplete() }
                                                }
                                            }
                                        }
                                    }
                                )
                        }
                    }
                    // brushtube 图片盖在骨上方，遮住下半截
                    if let img = UIImage(named: "brushtube", in: .module, compatibleWith: nil) {
                        Image(uiImage: img)
                            .resizable().scaledToFit()
                            .frame(width: 142, height: 180)
                            .allowsHitTesting(false)
                    }
                }
                .frame(width: 142, height: 180)
                .position(x: contX, y: contY)

                // 进度提示
                VStack {
                    Spacer()
                    Text("Drag ribs onto the guide lines  \(snappedCount)/5")
                        .font(.system(size: 13, design: .serif))
                        .foregroundColor(LFColors.brown.opacity(0.55))
                        .padding(.bottom, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func snapPoint(i: Int, pivot: CGPoint) -> CGPoint {
        let angle = snapAngles[i] * .pi / 180
        return CGPoint(
            x: pivot.x + boneLength * CGFloat(sin(angle)),
            y: pivot.y - boneLength * CGFloat(cos(angle))
        )
    }
}

// 第三面：放水
struct AddWaterView: View {
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void
    @State private var waterLevel: CGFloat = 0
    @State private var rippleScale: CGFloat = 1.0
    @State private var rippleOpacity: Double = 0
    @State private var tapCount = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LFColors.paper.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                .shadow(color: LFColors.brown.opacity(0.1), radius: 10)

            HStack(spacing: 16) {
                Text("Add\nWater")
                    .font(.system(size: 17, weight: .light, design: .serif))
                    .foregroundColor(LFColors.brown)
                    .multilineTextAlignment(.center)
                    .padding(.leading, 20)

                ZStack {
                    Circle()
                        .stroke(LFColors.brown.opacity(0.25), lineWidth: 1.5)
                        .frame(width: 130, height: 130)
                        .scaleEffect(rippleScale).opacity(rippleOpacity)

                    Image("basin", bundle: .module)
                        .resizable().scaledToFit()
                        .frame(width: 160, height: 160)

                    // 水位动画
                    if waterLevel > 0 {
                        RoundedRectangle(cornerRadius: 50)
                            .fill(Color.cyan.opacity(0.25))
                            .frame(width: 80, height: waterLevel * 40)
                            .offset(y: 20 - waterLevel * 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.trailing, 20)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 220)
        .padding(.horizontal, 28)
        .onTapGesture {
            tapCount += 1
            rippleOpacity = 0.6
            withAnimation(.easeOut(duration: 0.9)) { rippleScale = 2.0; rippleOpacity = 0 }
            withAnimation(.easeIn(duration: 0.5)) { waterLevel = min(waterLevel + 0.35, 1.0) }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { rippleScale = 1.0 }
            hasInteracted = true
            if tapCount >= 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { onComplete() }
            }
        }
    }
}

// 第四面：加颜料
struct AddPaintView: View {
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void
    @State private var drops: [(CGPoint, Color)] = []
    @State private var imageScale: CGFloat = 1.0
    @State private var tapCount = 0

    let dropColors: [Color] = [
        Color(red: 0.77, green: 0.12, blue: 0.23),
        Color(red: 0.18, green: 0.31, blue: 0.31),
        Color(red: 0.83, green: 0.69, blue: 0.22),
        Color(red: 0.53, green: 0.17, blue: 0.09),
        Color(red: 0.29, green: 0.51, blue: 0.42)
    ]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LFColors.paper.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                .shadow(color: LFColors.brown.opacity(0.1), radius: 10)

            ZStack {
                Image("painttable", bundle: .module)
                    .resizable().scaledToFit()
                    .frame(maxWidth: .infinity).frame(height: 170)
                    .padding(.horizontal, 16)
                    .scaleEffect(imageScale)

                // 颜料滴
                ForEach(drops.indices, id: \.self) { i in
                    Circle()
                        .fill(drops[i].1.opacity(0.8))
                        .frame(width: 14, height: 14)
                        .position(drops[i].0)
                }

                VStack {
                    HStack {
                        Spacer()
                        Text("Tap to add pigment")
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(LFColors.brown.opacity(0.65))
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6)
                                .fill(LFColors.paper.opacity(0.85)))
                            .padding(.trailing, 14).padding(.top, 10)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity).frame(height: 220)
        .padding(.horizontal, 28)
        .onTapGesture { location in
            tapCount += 1
            withAnimation(.spring(response: 0.3)) { imageScale = 1.05 }
            withAnimation(.spring(response: 0.3).delay(0.15)) { imageScale = 1.0 }
            let color = dropColors[tapCount % dropColors.count]
            withAnimation(.easeOut(duration: 0.4)) {
                drops.append((location, color))
            }
            hasInteracted = true
            if tapCount >= 4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onComplete() }
            }
        }
    }
}

// 第五面：搅动+放扇子
struct StirAndDipView: View {
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void
    @State private var phase: Int = 0  // 0=搅动 1=放扇子 2=完成
    @State private var stirPoints: [CGPoint] = []
    @State private var fanOffset: CGFloat = -80
    @State private var fanOpacity: Double = 0

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(LFColors.paper.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))
                .shadow(color: LFColors.brown.opacity(0.1), radius: 10)

            ZStack {
                Image("lacquerflow", bundle: .module)
                    .resizable().scaledToFit()
                    .frame(maxWidth: .infinity).frame(height: 170)
                    .padding(.horizontal, 16)

                // 搅动轨迹
                if phase == 0 {
                    Canvas { ctx, _ in
                        guard stirPoints.count > 1 else { return }
                        var path = Path()
                        path.move(to: stirPoints[0])
                        for pt in stirPoints.dropFirst() { path.addLine(to: pt) }
                        ctx.stroke(path, with: .color(LFColors.brown.opacity(0.5)),
                                   style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                    .frame(maxWidth: .infinity).frame(height: 170)
                    .padding(.horizontal, 16)
                    .contentShape(Rectangle())
                    .gesture(DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            stirPoints.append(val.location)
                            if stirPoints.count > 60 { stirPoints.removeFirst() }
                            hasInteracted = true
                            if stirPoints.count >= 40 {
                                withAnimation(.easeInOut(duration: 0.4)) { phase = 1 }
                            }
                        }
                    )
                }

                // 扇子入水动画
                if phase >= 1 {
                    Image("fan", bundle: .module)
                        .resizable().scaledToFit()
                        .frame(width: 100, height: 100)
                        .offset(y: fanOffset)
                        .opacity(fanOpacity)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.2)) {
                                fanOffset = 20
                                fanOpacity = 1.0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                phase = 2
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { onComplete() }
                            }
                        }
                }
            }

            VStack {
                Spacer()
                Text(phase == 0 ? "Swirl to stir the lacquer" : phase == 1 ? "Dipping the fan..." : "Pattern transferred!")
                    .font(.system(size: 13, design: .serif))
                    .foregroundColor(LFColors.brown.opacity(0.6))
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: .infinity).frame(height: 240)
        .padding(.horizontal, 28)
    }
}

// 第六面：定制画笔
struct CustomizeBrushStepView: View {
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void
    @State private var selectedBrush: Int? = nil
    @Environment(\.horizontalSizeClass) private var hSizeClass

    private var isIPad: Bool { hSizeClass == .regular }
    let brushNames = ["Fine Tip", "Medium", "Bold"]
    let brushWidths: [CGFloat] = [2, 5, 9]

    var body: some View {
        VStack(spacing: isIPad ? 28 : 20) {
            // 画笔预览
            HStack(spacing: isIPad ? 36 : 24) {
                ForEach(0..<3) { i in
                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(selectedBrush == i
                                      ? LFColors.brown.opacity(0.12)
                                      : LFColors.paper.opacity(0.6))
                                .frame(width: isIPad ? 96 : 72, height: isIPad ? 96 : 72)
                                .overlay(Circle()
                                    .stroke(selectedBrush == i
                                            ? LFColors.brown : LFColors.brown.opacity(0.2),
                                            lineWidth: selectedBrush == i ? 2 : 1))

                            if let img = UIImage(named: "brush", in: .module, compatibleWith: nil) {
                                Image(uiImage: img)
                                    .resizable().scaledToFit()
                                    .frame(width: isIPad ? 48 : 36, height: isIPad ? 48 : 36)
                            } else {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(LFColors.brown)
                                    .frame(width: brushWidths[i], height: isIPad ? 52 : 40)
                            }
                        }
                        .scaleEffect(selectedBrush == i ? 1.08 : 1.0)
                        .animation(.spring(response: 0.3), value: selectedBrush)

                        Text(brushNames[i])
                            .font(.system(size: isIPad ? 15 : 12, design: .serif))
                            .foregroundColor(selectedBrush == i ? LFColors.brown : LFColors.brown.opacity(0.5))
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) { selectedBrush = i }
                        hasInteracted = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onComplete() }
                    }
                }
            }

            Text("Choose your brush style")
                .font(.system(size: isIPad ? 15 : 12, design: .serif))
                .foregroundColor(LFColors.brown.opacity(0.5))
        }
        .padding(.vertical, isIPad ? 28 : 20)
        .frame(maxWidth: .infinity)
    }
}


struct InteractiveToolView: View {
    @Binding var hasInteracted: Bool
    let onComplete: () -> Void
    @EnvironmentObject var appState: AppState
    @Environment(\.horizontalSizeClass) private var hSizeClass

    @State private var paths: [[CGPoint]] = []
    @State private var currentPath: [CGPoint] = []
    @State private var drawingSize: CGSize = .zero

    private var isIPad: Bool { hSizeClass == .regular }

    var body: some View {
        VStack(spacing: 12) {
            Text("Draw your fan pattern")
                .font(.system(size: isIPad ? 16 : 13, weight: .medium, design: .serif))
                .foregroundColor(LFColors.brown)

            ZStack {
                // 扇面底纹
                if let img = UIImage(named: "rect", in: .module, compatibleWith: nil) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(maxWidth: .infinity).frame(height: isIPad ? 260 : 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .opacity(0.35)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LFColors.paper.opacity(0.6))
                        .frame(maxWidth: .infinity).frame(height: isIPad ? 260 : 200)
                }

                // 绘制层
                Canvas { ctx, size in
                    for pts in paths + (currentPath.isEmpty ? [] : [currentPath]) {
                        guard pts.count > 1 else { continue }
                        var path = Path()
                        path.move(to: pts[0])
                        for pt in pts.dropFirst() { path.addLine(to: pt) }
                        ctx.stroke(path, with: .color(Color(appState.selectedColor)),
                                   style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    }
                }
                .frame(maxWidth: .infinity).frame(height: isIPad ? 260 : 200)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { v in
                            currentPath.append(v.location)
                            hasInteracted = true
                        }
                        .onEnded { _ in
                            if !currentPath.isEmpty {
                                paths.append(currentPath)
                                appState.userDrawnPattern = paths
                                currentPath = []
                            }
                        }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(LFColors.brown.opacity(0.2), lineWidth: 1))

            HStack(spacing: 16) {
                Button {
                    if !paths.isEmpty { paths.removeLast() }
                    appState.userDrawnPattern = paths
                } label: {
                    Text("Undo")
                        .font(.system(size: isIPad ? 15 : 12, design: .serif))
                        .foregroundColor(LFColors.brown)
                        .padding(.horizontal, isIPad ? 24 : 18).padding(.vertical, isIPad ? 10 : 7)
                        .background(LFColors.paper.opacity(0.7))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(LFColors.brown.opacity(0.3), lineWidth: 1))
                }

                Button {
                    appState.userDrawnPattern = paths
                    onComplete()
                } label: {
                    Text("Done")
                        .font(.system(size: isIPad ? 15 : 12, weight: .semibold, design: .serif))
                        .foregroundColor(.white)
                        .padding(.horizontal, isIPad ? 32 : 24).padding(.vertical, isIPad ? 10 : 7)
                        .background(
                            Group {
                                if let uiImg = UIImage(named: "Union1", in: .module, compatibleWith: nil) {
                                    Image(uiImage: uiImg).resizable().scaledToFill()
                                } else { LFColors.brown }
                            }
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal, isIPad ? 28 : 20)
        .padding(.vertical, isIPad ? 20 : 16)
    }
}
