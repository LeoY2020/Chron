import UIKit

/// 分级触感反馈：轻 / 中 / 重。遵循"减少动态效果"辅助功能设置（开启后不触发触感）。
final class HapticsManager {
    static let shared = HapticsManager()

    enum Grade {
        case light
        case medium
        case heavy
    }

    private var lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private var mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private var heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        prepare()
    }

    /// 预激活各强度生成器，降低首次触发延迟。
    func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
    }

    /// 触发一次分级触感。开启"减少动态效果"时整体降级为静默。
    func impact(_ grade: Grade) {
        guard !UIAccessibility.isReduceMotionEnabled else { return }
        switch grade {
        case .light:
            lightGenerator.impactOccurred()
            lightGenerator.prepare()
        case .medium:
            mediumGenerator.impactOccurred()
            mediumGenerator.prepare()
        case .heavy:
            heavyGenerator.impactOccurred()
            heavyGenerator.prepare()
        }
    }
}
