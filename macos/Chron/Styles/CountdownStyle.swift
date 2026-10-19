import Foundation

/// 倒计时页的五种样式。
enum CountdownStyle: String, CaseIterable, Identifiable {
    case ring
    case sector
    case dial
    case plain
    case immersive

    var id: String { rawValue }

    var title: String {
        switch self {
        case .ring: return "Ring"
        case .sector: return "Sector"
        case .dial: return "Dial"
        case .plain: return "Plain"
        case .immersive: return "Immersive"
        }
    }

    var symbol: String {
        switch self {
        case .ring: return "circle.dashed"
        case .sector: return "chart.pie.fill"
        case .dial: return "clock"
        case .plain: return "textformat"
        case .immersive: return "arrow.up.left.and.arrow.down.right"
        }
    }
}