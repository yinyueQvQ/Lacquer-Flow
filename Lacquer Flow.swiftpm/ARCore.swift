import SwiftUI
import RealityKit
import ARKit
import Vision
import Combine

// MARK: - AR 核心逻辑

struct ARCreativeContainer: UIViewRepresentable {
    @ObservedObject var appState: AppState

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        guard ARWorldTrackingConfiguration.isSupported else { return arView }

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        arView.session.delegate = context.coordinator
        context.coordinator.arView = arView

        let tap = UITapGestureRecognizer(target: context.coordinator,
                                         action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tap)
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateState(appState: appState)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(appState: appState)
    }

    @MainActor
    class Coordinator: NSObject, ARSessionDelegate {
        var arView: ARView?
        var appState: AppState

        var waterPlane: ModelEntity?
        var fanRoot: Entity?
        var pivotNodes: [Entity] = []
        var paintBlobs: [ModelEntity] = []
        var fanPaperEntities: [ModelEntity] = []
        var droppedColors: [UIColor] = []
        var lastHandPosition: SIMD3<Float>?
        var transferElapsedTime: TimeInterval = 0
        var transferTimer: Timer?

        // 手腕位置平滑缓冲
        var wristHistory: [SIMD3<Float>] = []
        var lastPhase: AppState.Phase = .intro
        // 防止 Vision 并发处理导致 ARFrame 堆积
        nonisolated(unsafe) var isProcessingVision = false

        init(appState: AppState) {
            self.appState = appState
            super.init()
        }

        func updateState(appState: AppState) {
            self.appState = appState
            let prevPhase = lastPhase
            lastPhase = appState.currentPhase

            // 进入 transfer 阶段：显示扇子悬停，等待用户触发
            if appState.currentPhase == .transfer && prevPhase != .transfer {
                showFanHovering()
            }
            // 用户点击触发浸染
            if appState.currentPhase == .transfer && appState.userTriggeredDip {
                appState.userTriggeredDip = false
                performTransferAnimation()
            }
        }

        func showFanHovering() {
            guard let fan = fanRoot else { return }
            fan.isEnabled = true
            // 扇子悬停在水面上方，正立等待
            var tf = fan.transform
            tf.translation.y = 0.3
            tf.rotation = simd_quatf(angle: 0, axis: [1, 0, 0])
            fan.transform = tf
        }

        // MARK: - 点击交互

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView else { return }

            if appState.currentPhase == .arScan && waterPlane == nil {
                let location = sender.location(in: arView)
                var results = arView.raycast(from: location, allowing: .existingPlaneGeometry, alignment: .horizontal)
                if results.isEmpty { results = arView.raycast(from: location, allowing: .existingPlaneInfinite, alignment: .horizontal) }
                if results.isEmpty { results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal) }

                if let result = results.first {
                    createWaterPlane(at: result.worldTransform)
                    appState.currentPhase = .creation
                    appState.handStatus = ""
                } else {
                    appState.handStatus = "No plane found, keep scanning"
                }
            } else if appState.currentPhase == .creation && waterPlane != nil {
                let location = sender.location(in: arView)
                let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
                if let result = results.first {
                    addPaintBlob(at: result.worldTransform)
                }
            }
        }

        // MARK: - 水面（圆形水池）

        func createWaterPlane(at transform: simd_float4x4) {
            let anchor = AnchorEntity(world: transform)

            // 用多边形近似圆形（iOS 16 兼容，generateCylinder 需要 iOS 18）
            // 用 generatePlane + 视觉上的圆形材质即可，碰撞检测用方形不影响体验
            let mesh = MeshResource.generatePlane(width: 0.5, depth: 0.5, cornerRadius: 0.25)
            var material = PhysicallyBasedMaterial()
            material.baseColor = .init(tint: UIColor(red: 0.75, green: 0.88, blue: 0.98, alpha: 1.0))
            material.roughness = 0.05
            material.metallic  = 0.1
            material.blending  = .transparent(opacity: 0.65)

            let plane = ModelEntity(mesh: mesh, materials: [material])
            plane.generateCollisionShapes(recursive: true)
            anchor.addChild(plane)
            arView?.scene.addAnchor(anchor)
            waterPlane = plane

            createCustomizedFan(parent: anchor)
            fanRoot?.isEnabled = false
        }

        // MARK: - 扇子（颜色与用户选择对应）

        func createCustomizedFan(parent: Entity) {
            let root = Entity()
            root.position = [0, 0.3, 0]
            parent.addChild(root)
            fanRoot = root

            let config = appState.fanCustomization

            // 扇柄颜色
            var handleColor: UIColor
            switch config.handleStyle {
            case .classic: handleColor = UIColor(red: 0.45, green: 0.25, blue: 0.10, alpha: 1)
            case .elegant: handleColor = UIColor(red: 0.65, green: 0.45, blue: 0.22, alpha: 1)
            case .modern:  handleColor = UIColor(white: 0.35, alpha: 1)
            }
            var handleMat = UnlitMaterial()
            handleMat.color = .init(tint: handleColor)

            // 扇面底色（白色或木色）
            let surfaceUIColor: UIColor
            switch config.fanColor {
            case .white: surfaceUIColor = UIColor(white: 0.97, alpha: 1)
            case .wood:  surfaceUIColor = UIColor(red: 0.88, green: 0.72, blue: 0.48, alpha: 1)
            }
            var paperMat = UnlitMaterial()
            paperMat.color = .init(tint: surfaceUIColor)

            // 流苏颜色
            var tasselColor: UIColor
            switch config.tasselStyle {
            case .red:  tasselColor = UIColor(red: 0.80, green: 0.10, blue: 0.10, alpha: 1)
            case .gold: tasselColor = UIColor(red: 0.85, green: 0.70, blue: 0.15, alpha: 1)
            case .jade: tasselColor = UIColor(red: 0.20, green: 0.60, blue: 0.35, alpha: 1)
            }
            var tasselMat = UnlitMaterial()
            tasselMat.color = .init(tint: tasselColor)

            switch config.fanShape {
            case .folding:
                // 折扇：5 根骨架 + 扇纸
                let boneMesh  = MeshResource.generateBox(size: [0.025, 0.22, 0.004])
                let paperMesh = MeshResource.generateBox(size: [0.055, 0.16, 0.001])

                for i in 0..<5 {
                    let pivot = Entity()
                    pivot.position = [0, -0.11, 0]
                    root.addChild(pivot)
                    pivotNodes.append(pivot)

                    let bone = ModelEntity(mesh: boneMesh, materials: [handleMat])
                    bone.position = [0, 0.11, 0]

                    // 前后两层扇纸，保证翻转后依然可见
                    let frontPaper = ModelEntity(mesh: paperMesh, materials: [paperMat])
                    frontPaper.position = [0, 0.04, 0.003]
                    bone.addChild(frontPaper)
                    fanPaperEntities.append(frontPaper)

                    let backPaper = ModelEntity(mesh: paperMesh, materials: [paperMat])
                    backPaper.position = [0, 0.04, -0.003]
                    bone.addChild(backPaper)
                    fanPaperEntities.append(backPaper)

                    pivot.addChild(bone)
                    pivot.orientation = simd_quatf(angle: Float(i - 2) * 0.32, axis: [0, 0, 1])

                    if i == 2 {
                        let tassel = ModelEntity(
                            mesh: .generateBox(size: [0.008, 0.08, 0.008]),
                            materials: [tasselMat]
                        )
                        tassel.position = [0, -0.13, 0]
                        pivot.addChild(tassel)
                    }
                }

            case .round:
                // 圆扇：正面 + 背面（双面）+ 扇柄 + 流苏
                // generatePlane 默认在 XZ 平面（水平），旋转 90° 使其竖立朝前
                let discMesh = MeshResource.generatePlane(width: 0.22, depth: 0.22, cornerRadius: 0.11)
                // 正面
                let discFront = ModelEntity(mesh: discMesh, materials: [paperMat])
                discFront.position = [0, 0.07, 0.001]
                discFront.orientation = simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                root.addChild(discFront)
                fanPaperEntities.append(discFront)
                // 背面（绕 Y 轴翻转 180°，使法线朝后）
                let discBack = ModelEntity(mesh: discMesh, materials: [paperMat])
                discBack.position = [0, 0.07, -0.001]
                discBack.orientation = simd_quatf(angle: -.pi / 2, axis: [1, 0, 0])
                root.addChild(discBack)
                fanPaperEntities.append(discBack)

                // 扇柄粗细保持统一，由颜色与细节体现风格差异
                let handleW: Float = 0.016
                // 扇柄顶端紧贴扇面底部（扇面中心 y=0.07，半径 0.11，底部 y=-0.04）
                let handleMesh = MeshResource.generateBox(size: [handleW, 0.18, handleW])
                let handleEntity = ModelEntity(mesh: handleMesh, materials: [handleMat])
                handleEntity.position = [0.0, Float(-0.04 - 0.09), 0.0]   // 顶端 = -0.04，中心下移半长
                root.addChild(handleEntity)

                // 流苏
                let tasselMesh = MeshResource.generateBox(size: [0.008, 0.07, 0.008])
                let tassel = ModelEntity(mesh: tasselMesh, materials: [tasselMat])
                tassel.position = [0.0, Float(-0.04 - 0.18 - 0.035), 0.0]
                root.addChild(tassel)
            }
        }

        // MARK: - 漆滴艺术效果

        func addPaintBlob(at transform: simd_float4x4) {
            guard let water = waterPlane, let waterParent = water.parent else { return }

            let waterWorldPos = water.position(relativeTo: nil)
            let tapWorldPos = SIMD3<Float>(transform.columns.3.x,
                                           transform.columns.3.y,
                                           transform.columns.3.z)

            // 圆形水池半径 0.25m，颜料限制在圆内（留 0.03m 边距）
            let poolRadius: Float = 0.22
            var dx = tapWorldPos.x - waterWorldPos.x
            var dz = tapWorldPos.z - waterWorldPos.z
            let dist = sqrt(dx * dx + dz * dz)
            if dist > poolRadius {
                let scale = poolRadius / dist
                dx *= scale
                dz *= scale
            }

            let color = appState.selectedColor
            // 用水面本地坐标 + 偏移量，保证 blob 在正确位置（本地坐标系）
            let waterLocal = water.position
            let basePos: SIMD3<Float> = [
                waterLocal.x + dx,
                waterLocal.y + 0.006,
                waterLocal.z + dz
            ]

            // 主漆滴（扁椭球）— 半径缩小到 0.010
            let blobRadius: Float = 0.010
            let mainBlob = ModelEntity(
                mesh: MeshResource.generateSphere(radius: blobRadius),
                materials: [SimpleMaterial(color: color, isMetallic: false)]
            )
            mainBlob.position = basePos
            mainBlob.scale = [1.0, 0.15, 1.0]
            waterParent.addChild(mainBlob)
            paintBlobs.append(mainBlob)
            droppedColors.append(color)

            // 扩散上限：铺开后直径不超过水池剩余空间，且最大不超过 0.06m 半径
            let maxBlobWorldRadius: Float = min(0.06, poolRadius - dist - 0.01)
            let maxSpread: Float = max(1.0, maxBlobWorldRadius / blobRadius)
            var spreadT = mainBlob.transform
            spreadT.scale = [maxSpread, 0.04, maxSpread]
            mainBlob.move(to: spreadT, relativeTo: mainBlob.parent, duration: 1.8,
                          timingFunction: .easeOut)

            // 涟漪环：大小同样受水池边界约束
            let rippleInitSize: Float = blobRadius * 2
            let rippleMesh = MeshResource.generatePlane(width: rippleInitSize, depth: rippleInitSize,
                                                        cornerRadius: blobRadius)
            let ripple = ModelEntity(
                mesh: rippleMesh,
                materials: [SimpleMaterial(color: color.withAlphaComponent(0.28), isMetallic: false)]
            )
            ripple.position = [basePos.x, basePos.y + 0.001, basePos.z]
            waterParent.addChild(ripple)
            paintBlobs.append(ripple)
            var rippleT = ripple.transform
            let rippleMax = min(maxSpread * 1.4, (poolRadius - dist) / rippleInitSize * 0.5)
            rippleT.scale = [rippleMax, 1.0, rippleMax]
            ripple.move(to: rippleT, relativeTo: ripple.parent, duration: 0.9,
                        timingFunction: .easeOut)

            // 第二道涟漪（稍慢，更淡）
            let ripple2 = ModelEntity(
                mesh: rippleMesh,
                materials: [SimpleMaterial(color: color.withAlphaComponent(0.14), isMetallic: false)]
            )
            ripple2.position = [basePos.x, basePos.y + 0.0005, basePos.z]
            waterParent.addChild(ripple2)
            paintBlobs.append(ripple2)
            var ripple2T = ripple2.transform
            ripple2T.scale = [rippleMax * 0.75, 1.0, rippleMax * 0.75]
            ripple2.move(to: ripple2T, relativeTo: ripple2.parent, duration: 1.4,
                         timingFunction: .easeOut)

            // 溅射小滴（3~4 个，也限制在圆内）
            let splashCount = Int.random(in: 3...4)
            for j in 0..<splashCount {
                let angle = Float(j) / Float(splashCount) * .pi * 2 + Float.random(in: -0.4...0.4)
                let splashDist = Float.random(in: 0.02...0.06)
                var sx = dx + cos(angle) * splashDist
                var sz = dz + sin(angle) * splashDist
                let sd = sqrt(sx * sx + sz * sz)
                if sd > poolRadius {
                    sx *= poolRadius / sd
                    sz *= poolRadius / sd
                }
                let splashPos: SIMD3<Float> = [waterLocal.x + sx, basePos.y, waterLocal.z + sz]
                let splash = ModelEntity(
                    mesh: MeshResource.generateSphere(radius: Float.random(in: 0.005...0.010)),
                    materials: [SimpleMaterial(color: color.withAlphaComponent(0.7), isMetallic: false)]
                )
                splash.position = splashPos
                splash.scale = [1.0, 0.2, 1.0]
                waterParent.addChild(splash)
                paintBlobs.append(splash)

                var splashT = splash.transform
                splashT.scale = [Float.random(in: 1.2...2.0), 0.07, Float.random(in: 1.2...2.0)]
                splash.move(to: splashT, relativeTo: splash.parent, duration: 1.0,
                            timingFunction: .easeOut)
            }

            // 同步到 AppState（供 2D 展示用）
            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            appState.droppedColors.append(Color(red: r, green: g, blue: b, opacity: a))
        }

        func performTransferAnimation() {
            guard let fan = fanRoot else { return }
            fan.isEnabled = true

            // 若没有滴颜料，用扇面底色作为 fallback，保证动画始终执行
            var paintColors = droppedColors.isEmpty
                ? paintBlobs.compactMap { ($0.model?.materials.first as? SimpleMaterial)?.color.tint }
                : droppedColors
            if paintColors.isEmpty {
                paintColors = [UIColor(red: 0.6, green: 0.2, blue: 0.1, alpha: 1)]
            }

            let totalDuration: TimeInterval = 5.5
            let frameInterval: TimeInterval = 1.0 / 60.0
            let startY: Float  = 0.3
            let contactY: Float = 0.015
            let endY: Float    = 0.3
            // 扇面朝下：绕 X 轴旋转 180°（扇面倒扣浸入水中）
            let dipOrientation   = simd_quatf(angle: .pi, axis: [1, 0, 0])
            let upOrientation    = simd_quatf(angle: 0,   axis: [1, 0, 0])
            transferElapsedTime = 0

            transferTimer?.invalidate()
            let timer = Timer(timeInterval: frameInterval, repeats: true) { [weak self] _ in
                guard let s = self else { return }
                DispatchQueue.main.async {

                    s.transferElapsedTime += frameInterval
                    let progress = min(s.transferElapsedTime / totalDuration, 1.0)

                    if progress < 0.25 {
                        // 阶段1：扇子下降 + 同步旋转扇面朝下
                        let p = progress / 0.25
                        let eased = s.easeInOutCubic(p)
                        var tf = fan.transform
                        tf.translation.y = startY + (contactY - startY) * Float(eased)
                        tf.rotation = simd_slerp(upOrientation, dipOrientation, Float(eased))
                        fan.transform = tf

                    } else if progress < 0.65 {
                        // 阶段2：扇面浸在水中吸色，轻微抖动
                        let p = (progress - 0.25) / 0.4
                        let cp = pow(p, 0.6)

                        var tf = fan.transform
                        tf.translation.y = contactY + Float(sin(p * .pi * 6) * 0.003)
                        tf.rotation = dipOrientation
                        fan.transform = tf

                        // 先把所有颜料颜色做一次平均，让浸染后的扇面颜色更加稳定、整体
                        var avgR: CGFloat = 0, avgG: CGFloat = 0, avgB: CGFloat = 0
                        for c in paintColors {
                            var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                            c.getRed(&r, green: &g, blue: &b, alpha: nil)
                            avgR += r; avgG += g; avgB += b
                        }
                        let countColors = max(1, paintColors.count)
                        avgR /= CGFloat(countColors)
                        avgG /= CGFloat(countColors)
                        avgB /= CGFloat(countColors)

                        let baseR: CGFloat = s.appState.fanCustomization.fanColor == .white ? 0.97 : 0.88
                        let baseG: CGFloat = s.appState.fanCustomization.fanColor == .white ? 0.97 : 0.72
                        let baseB: CGFloat = s.appState.fanCustomization.fanColor == .white ? 0.97 : 0.48

                        // cp 从 0→1 时，线性从扇面底色过渡到平均颜料色，颜色不会来回跳变
                        for (idx, paper) in s.fanPaperEntities.enumerated() {
                            let subtle = 0.96 + 0.06 * CGFloat(idx % 3) / 2.0  // 轻微的深浅变化
                            let tr = (baseR + (avgR - baseR) * CGFloat(cp)) * subtle
                            let tg = (baseG + (avgG - baseG) * CGFloat(cp)) * subtle
                            let tb = (baseB + (avgB - baseB) * CGFloat(cp)) * subtle

                            var mat = UnlitMaterial()
                            mat.color = .init(tint: UIColor(red: tr, green: tg, blue: tb, alpha: 1.0))
                            paper.model?.materials = [mat]
                        }

                        for blob in s.paintBlobs {
                            let shrink = max(0.0, min(1.0, (p - 0.15) / 0.65))
                            var bt = blob.transform
                            let sx = bt.scale.x * Float(1 - shrink * 0.02)
                            bt.scale = [max(0.05, sx), bt.scale.y, max(0.05, sx)]
                            blob.transform = bt
                            blob.isEnabled = shrink < 0.98
                        }
                        if p > 0.55 { s.waterPlane?.isEnabled = false }

                    } else if progress < 0.85 {
                        // 阶段3：扇子抬起，同时翻转回正立
                        let p = (progress - 0.65) / 0.2
                        let eased = s.easeInOutCubic(p)
                        var tf = fan.transform
                        tf.translation.y = contactY + (endY - contactY) * Float(eased)
                        tf.rotation = simd_slerp(dipOrientation, upOrientation, Float(eased))
                        fan.transform = tf

                    } else {
                        // 阶段4：保持正立悬停
                        var tf = fan.transform
                        tf.translation.y = endY
                        tf.rotation = upOrientation
                        fan.transform = tf
                    }

                    if progress >= 1.0 {
                        s.transferTimer?.invalidate()
                        s.transferTimer = nil
                        s.paintBlobs.forEach { $0.isEnabled = false }
                        s.waterPlane?.isEnabled = false
                        s.appState.currentPhase = .handMagic
                    }
                }
            }
            transferTimer = timer
            RunLoop.main.add(timer, forMode: .common)
        }

        func easeInOutCubic(_ value: Double) -> Double {
            value < 0.5 ? 4 * value * value * value : 1 + (2 * value - 2) * (2 * value - 2) * (2 * value - 2) / 2
        }

        // MARK: - ARSessionDelegate

        nonisolated func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
            for anchor in anchors where anchor is ARPlaneAnchor {
                Task { @MainActor [weak self] in
                    self?.appState.handStatus = "Plane detected, tap to place water"
                }
                break
            }
        }

        nonisolated func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {}

        nonisolated func session(_ session: ARSession, didFailWithError error: Error) {
            let msg = error.localizedDescription
            Task { @MainActor [weak self] in
                self?.appState.handStatus = "AR error: \(msg)"
            }
        }

        // MARK: - Vision 手势（handMagic 阶段：扇子跟手）

        nonisolated func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard frame.timestamp.remainder(dividingBy: 0.05) < 0.01 else { return }
            // 若上一帧 Vision 还没处理完，直接跳过，避免 ARFrame 堆积
            guard !isProcessingVision else { return }
            isProcessingVision = true
            defer { isProcessingVision = false }

            let buffer = frame.capturedImage
            let request = VNDetectHumanHandPoseRequest()
            request.maximumHandCount = 1

            do {
                try VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up).perform([request])
                guard let obs = request.results?.first else {
                    Task { @MainActor [weak self] in
                        guard self?.appState.currentPhase == .handMagic else { return }
                        self?.appState.handStatus = "No hand detected"
                    }
                    return
                }

                let thumb  = try obs.recognizedPoints(.thumb)[.thumbTip]
                let index  = try obs.recognizedPoints(.indexFinger)[.indexTip]
                let middle = try obs.recognizedPoints(.middleFinger)[.middleTip]
                let ring   = try obs.recognizedPoints(.ringFinger)[.ringTip]
                let wrist  = try obs.recognizedPoints(.all)[.wrist]
                let indexMCP = try obs.recognizedPoints(.indexFinger)[.indexMCP]
                let littleMCP = try obs.recognizedPoints(.littleFinger)[.littleMCP]

                guard let th = thumb, let idx = index, let mi = middle,
                      let ri = ring, let wr = wrist,
                      th.confidence > 0.5, wr.confidence > 0.5 else { return }

                // 开合度：拇指与食指距离
                let pinchDist = hypot(th.location.x - idx.location.x,
                                      th.location.y - idx.location.y)
                let openness = Float(min(max((pinchDist - 0.03) / 0.12, 0), 1))

                // 握姿检测：食指/中指/无名指指尖都靠近手腕 → 握拳
                let idxDist = hypot(idx.location.x - wr.location.x, idx.location.y - wr.location.y)
                let miDist  = hypot(mi.location.x  - wr.location.x, mi.location.y  - wr.location.y)
                let riDist  = hypot(ri.location.x  - wr.location.x, ri.location.y  - wr.location.y)
                let isGrip  = idxDist < 0.18 && miDist < 0.18 && riDist < 0.18

                // 圆扇用手掌中心（食指根 + 小指根 的中点），折扇用手腕
                let palmX: CGFloat
                let palmY: CGFloat
                if let iMCP = indexMCP, let lMCP = littleMCP,
                   iMCP.confidence > 0.4, lMCP.confidence > 0.4 {
                    palmX = (iMCP.location.x + lMCP.location.x) / 2
                    palmY = (iMCP.location.y + lMCP.location.y) / 2
                } else {
                    palmX = wr.location.x
                    palmY = wr.location.y
                }

                let wx = wr.location.x
                let wy = wr.location.y

                Task { @MainActor [weak self] in
                    guard let s = self, s.appState.currentPhase == .handMagic else { return }
                    let b = UIScreen.main.bounds
                    let isRound = s.appState.fanCustomization.fanShape == .round
                    // 圆扇跟手掌中心，折扇跟手腕
                    let trackX = isRound ? palmX : wx
                    let trackY = isRound ? palmY : wy
                    let pt = CGPoint(x: trackX * b.width, y: (1 - trackY) * b.height)
                    if isRound {
                        s.appState.handStatus = isGrip
                            ? "Fist held — fan stays in place"
                            : "Open hand — fan follows you"
                    } else {
                        s.appState.handStatus = isGrip
                            ? "Holding fan — open hand to spread, pinch to close"
                            : "Make a fist to grab the fan"
                    }
                    s.updateFan(screenPoint: pt, openness: openness, isGrip: isGrip)
                }
            } catch {}
        }

        // MARK: - Fan follows hand only while gripping (folding) or open hand (round)

        func updateFan(screenPoint: CGPoint, openness: Float, isGrip: Bool) {
            guard let fan = fanRoot, let arView = arView else { return }

            let isRound = appState.fanCustomization.fanShape == .round
            // Folding: grip = follow hand. Round: open hand = follow hand.
            let shouldFollow = isRound ? !isGrip : isGrip

            if shouldFollow {
                var targetPos: SIMD3<Float>?

                if let query = arView.makeRaycastQuery(from: screenPoint,
                                                        allowing: .estimatedPlane,
                                                        alignment: .any) {
                    if let result = arView.session.raycast(query).first {
                        targetPos = [result.worldTransform.columns.3.x,
                                     result.worldTransform.columns.3.y + 0.12,
                                     result.worldTransform.columns.3.z]
                    }
                }

                if targetPos == nil {
                    let cam = arView.cameraTransform
                    let fwd = SIMD3<Float>(-cam.matrix.columns.2.x,
                                           -cam.matrix.columns.2.y,
                                           -cam.matrix.columns.2.z)
                    targetPos = cam.translation + fwd * 0.45
                }

                if let tp = targetPos {
                    let smooth: Float = isRound ? 0.15 : 0.30
                    let cur = fan.position(relativeTo: nil)
                    let next = cur * (1 - smooth) + tp * smooth
                    fan.setPosition(next, relativeTo: nil)
                    lastHandPosition = next

                    fan.look(at: arView.cameraTransform.translation,
                             from: fan.position(relativeTo: nil),
                             relativeTo: nil)
                }
            } else {
                // Fan stays in place; cache position for smooth next transition
                lastHandPosition = fan.position(relativeTo: nil)
            }

            // Folding fan blade openness (round fan has no pivots)
            let targetOpenness: Float = isGrip ? 1.0 : openness
            for (i, pivot) in pivotNodes.enumerated() {
                pivot.orientation = simd_quatf(angle: Float(i - 2) * 0.32 * targetOpenness,
                                               axis: [0, 0, 1])
            }
        }
    }
}

extension simd_float4x4 {
    var translation: SIMD3<Float> { [columns.3.x, columns.3.y, columns.3.z] }
}
