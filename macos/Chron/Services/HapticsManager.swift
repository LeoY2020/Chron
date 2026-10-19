import Foundation
import AppKit
import Combine

/// 桌面端"触感"：分级系统音 + 微视觉脉冲（由 RootView 叠加）。
/// 没有触感硬件的桌面平台以降级后的轻声音 + 微动效替代，遵循"减少动态效果"设置。
final class HapticsManager: ObservableObject {
    static let shared = HapticsManager()

    enum Grade: Int, Equatable {
        case light = 0
        case medium = 1
        case heavy = 2
    }

    /// 每次反馈自增，供界面以 .id / onChange 触发微脉冲。
    @Published private(set) var pulseID = 0
    @Published private(set) var lastGrade: Grade = .light

    private var counter = 0

    private init() {}

    /// 是否开启"减少动态效果"：开启后全部反馈静默。
    var reduceMotion: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    func prepare() {}

    /// 触发一次分级反馈。
    func impact(_ grade: Grade) {
        guard !reduceMotion else { return }
        lastGrade = grade
        play(soundName(for: grade))
        bump()
    }

    /// 专注轮次结束 / 倒计时归零：柔和短促的一声。
    func completion() {
        guard !reduceMotion else { return }
        lastGrade = .heavy
        play("Glass")
        bump()
    }

    private func bump() {
        counter += 1
        pulseID = counter
    }

    private func play(_ name: String) {
        if let sound = NSSound(named: name) {
            sound.stop()
            sound.play()
        } else {
            NSSound.beep()
        }
    }

    private func soundName(for grade: Grade) -> String {
        switch grade {
        case .light: return "Tink"
        case .medium: return "Pop"
        case .heavy: return "Glass"
        }
    }
}