import SwiftUI

// MARK: - TutorialStep enum

enum TutorialStep: Int, CaseIterable {
    case scrapeLacquer = 0  // 刮漆
    case addWater            // 放水
    case addPaint            // 加颜料
    case stirAndDip          // 搅动+放扇子
    case assembleBones       // 扇骨拼装（移到自定义前）
    case customizeBrush      // 定制画笔
    case customizeFan        // 自定义扇面

    var title: String {
        switch self {
        case .scrapeLacquer:  return "Harvest Lacquer"
        case .assembleBones:  return "Assemble Bones"
        case .addWater:       return "Fill the Basin"
        case .addPaint:       return "Add Pigment"
        case .stirAndDip:     return "Stir & Dip"
        case .customizeBrush: return "Customize Brush"
        case .customizeFan:   return "Design Your Fan"
        }
    }

    var description: String {
        switch self {
        case .scrapeLacquer:
            return "Scrape raw lacquer from the tree. Swipe across the bark to collect the sap."
        case .assembleBones:
            return "Drag each fan rib from the holder into the guide lines to build your fan frame."
        case .addWater:
            return "Fill the basin with still, clean water. The water is the canvas for your pattern."
        case .addPaint:
            return "Tap the paint bottles to drop pigmented lacquer onto the water surface."
        case .stirAndDip:
            return "Swirl the lacquer gently, then lower the fan to pick up the pattern."
        case .customizeBrush:
            return "Choose your brush style to personalize your fan-making experience."
        case .customizeFan:
            return "Draw your own pattern on the fan surface. This will appear in AR."
        }
    }

    var knowledgeTitle: String {
        switch self {
        case .scrapeLacquer:  return "The Art of Lacquer Harvesting"
        case .assembleBones:  return "Fan Bone Craftsmanship"
        case .addWater:       return "The Role of Water"
        case .addPaint:       return "Traditional Pigments"
        case .stirAndDip:     return "The Marbling Moment"
        case .customizeBrush: return "Brush Traditions"
        case .customizeFan:   return "Fan Surface Design"
        }
    }

    var knowledgeBody: String {
        switch self {
        case .scrapeLacquer:
            return "Raw lacquer (生漆) is harvested from the Toxicodendron vernicifluum tree by making careful incisions in the bark. The milky sap oxidizes and darkens on contact with air. This natural lacquer has been used in Chinese craftsmanship for over 7,000 years, prized for its extraordinary durability and deep, lustrous finish."
        case .assembleBones:
            return "Traditional folding fan ribs (扇骨) are crafted from bamboo, sandalwood, or fragrant woods. Each rib is hand-shaped, sanded, and polished over many hours. The number of ribs — typically 7 to 30 — determines the fan's spread and elegance. A single pivot pin at the base holds all ribs together in perfect balance."
        case .addWater:
            return "The water basin is the heart of the marbling process. Still, clean water allows lacquer to float freely on the surface. Artisans traditionally use filtered spring water at around 20°C. Too cold and the lacquer won't spread; too warm and it sinks. The stillness of the water is as important as its purity."
        case .addPaint:
            return "Mineral pigments mixed with lacquer create vibrant, long-lasting colors. Traditional hues include vermilion (朱砂), azurite (石青), malachite (石绿), and gold powder (金粉). Each drop spreads into unique organic shapes on the water surface — no two patterns are ever identical, making every fan a one-of-a-kind artwork."
        case .stirAndDip:
            return "Using a fine bamboo tool, the floating lacquer is gently swirled to create flowing patterns. The fan is then carefully lowered onto the water at a precise angle, picking up the design in a single fluid motion. This critical moment requires years of practice — the angle, speed, and pressure all shape the final result."
        case .customizeBrush:
            return "In traditional lacquer art, the brush (签) is as important as the lacquer itself. Different brush tips create different pattern effects — fine tips for delicate swirls, broad tips for bold strokes. Artisans often spend years developing their signature brush technique."
        case .customizeFan:
            return "The fan surface (扇面) is the canvas of the lacquer artist. Traditionally made from silk, paper, or thin wood, the surface is prepared with multiple base coats before the marbling step. The final pattern is sealed with clear lacquer, preserving the design for generations."
        }
    }

    // 知识面板配图（每步对应不同图片）
    var knowledgeImageName: String {
        switch self {
        case .scrapeLacquer:  return "group6"
        case .assembleBones:  return "fan"
        case .addWater:       return "basin"
        case .addPaint:       return "painttable"
        case .stirAndDip:     return "lacquerflow"
        case .customizeBrush: return "brush"
        case .customizeFan:   return "rect"
        }
    }

    // 对应的教程视频文件名（无扩展名），nil 表示无视频
    var videoName: String? {
        switch self {
        case .scrapeLacquer:  return "漆液"
        case .addWater:       return "倒水"
        case .addPaint:       return "倒颜料"
        case .stirAndDip:     return "搅拌"
        default:              return nil
        }
    }
}

// MARK: - 全局状态

class AppState: ObservableObject {
    enum Phase {
        case intro          // Intro
        case tutorial       // Tutorial
        case customization  // Customization
        case arScan         // AR Scan
        case creation       // Paint Creation
        case transfer       // Transfer to Fan
        case handMagic      // Hand Gesture Magic
        case outro          // Outro
    }

    @Published var currentPhase: Phase = .intro
    @Published var selectedColor: UIColor = .red
    @Published var fanOpenness: Float = 1.0
    @Published var handStatus: String = "Looking for hand..."

    // 教程状态
    @Published var currentTutorialStep: TutorialStep = .scrapeLacquer

    // 扇子自定义数据
    @Published var fanCustomization = FanCustomization()

    // 用户绘制的图案
    @Published var userDrawnPattern: [[CGPoint]] = []
    @Published var patternPlacement: TextPlacement = .surface

    // 用户在AR中滴入的漆色
    @Published var droppedColors: [Color] = []

    // 用户触发浸染
    @Published var userTriggeredDip = false

    func reset() {
        currentTutorialStep = .scrapeLacquer
        fanCustomization = FanCustomization()
        userDrawnPattern = []
        droppedColors = []
        userTriggeredDip = false
        handStatus = "Looking for hand..."
        fanOpenness = 1.0
        selectedColor = .red
    }
}
