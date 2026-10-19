import Foundation

/// 时钟页的五种样式。
enum ClockStyle: String, CaseIterable, Identifiable {
    case analog
    case plain
    case immersive
    case sevenSegment
    case sun

    var id: String { rawValue }

    var title: String {
        switch self {
        case .analog: return "Analog"
        case .plain: return "Plain"
        case .immersive: return "Immersive"
        case .sevenSegment: return "Seven-segment"
        case .sun: return "Sun"
        }
    }

    var symbol: String {
        switch self {
        case .analog: return "clock"
        case .plain: return "textformat"
        case .immersive: return "arrow.up.left.and.arrow.down.right"
        case .sevenSegment: return "rectangle.split.3x1"
        case .sun: return "sun.max"
        }
    }
}
