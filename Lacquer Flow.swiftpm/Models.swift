import SwiftUI

// MARK: - 1. 数据模型

// --- Design tokens ---
struct LFColors {
    static let paper      = Color(red: 0.961, green: 0.929, blue: 0.863)
    static let brown      = Color(red: 0.361, green: 0.239, blue: 0.118)
    static let lightBrown = Color(red: 0.545, green: 0.380, blue: 0.220)
    static let gold       = Color(red: 0.831, green: 0.690, blue: 0.220)
    static let ink        = Color(red: 0.180, green: 0.141, blue: 0.102)
}

// --- 扇子自定义模型 ---
struct FanCustomization {
    var fanShape: FanShape = .folding
    var handleStyle: HandleStyle = .classic
    var surfacePattern: SurfacePattern = .plain
    var tasselStyle: TasselStyle = .red
    var fanColor: FanColor = .white
    var customText: String = ""
    var textPlacement: TextPlacement = .handle
}

enum FanShape: String, CaseIterable, Identifiable {
    case folding = "Folding"
    case round   = "Round"
    var id: String { rawValue }
}

enum HandleStyle: String, CaseIterable, Identifiable {
    case classic = "Classic"
    case elegant = "Elegant"
    case modern  = "Modern"
    var id: String { rawValue }
}

enum SurfacePattern: String, CaseIterable, Identifiable {
    case plain       = "Plain"
    case floral      = "Floral"
    case landscape   = "Landscape"
    case calligraphy = "Calligraphy"
    var id: String { rawValue }
}

enum FanColor: String, CaseIterable, Identifiable {
    case white = "White"
    case wood  = "Wood"
    var id: String { rawValue }
    var tintColor: Color {
        switch self {
        case .white: return .white
        case .wood:  return Color(red: 0.85, green: 0.68, blue: 0.45)
        }
    }
    var displayColor: Color {
        switch self {
        case .white: return Color(white: 0.95)
        case .wood:  return Color(red: 0.75, green: 0.55, blue: 0.30)
        }
    }
}

enum TextPlacement: String, CaseIterable, Identifiable {
    case handle  = "Handle"
    case surface = "Surface"
    var id: String { rawValue }
}

enum TasselStyle: String, CaseIterable, Identifiable {
    case red  = "Red Tassel"
    case gold = "Gold Tassel"
    case jade = "Jade Tassel"
    var id: String { rawValue }
}

struct AppColors {
    static let palettes: [UIColor] = [
        UIColor(red: 0.77, green: 0.12, blue: 0.23, alpha: 0.85), // 朱红
        UIColor(red: 0.18, green: 0.31, blue: 0.31, alpha: 0.8), // 石青
        UIColor(red: 0.05, green: 0.03, blue: 0.07, alpha: 0.9), // 黛黑
        UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 0.75), // 金
        UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 0.7), // 绢白
        UIColor(red: 0.53, green: 0.17, blue: 0.09, alpha: 0.85), // 赭石
        UIColor(red: 0.29, green: 0.51, blue: 0.42, alpha: 0.8), // 青绿
        UIColor(red: 0.85, green: 0.44, blue: 0.58, alpha: 0.75), // 藕荷
        UIColor(red: 0.47, green: 0.27, blue: 0.58, alpha: 0.8), // 紫檀
        UIColor(red: 0.93, green: 0.51, blue: 0.18, alpha: 0.75), // 橘黄
        UIColor(red: 0.13, green: 0.27, blue: 0.42, alpha: 0.85), // 靛蓝
        UIColor(red: 0.67, green: 0.73, blue: 0.62, alpha: 0.7) // 月白
    ]
}
