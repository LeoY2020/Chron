#pragma once

/// 分级反馈：桌面端以极轻的提示音代替触感，并受“减弱动效”偏好约束。
namespace Feedback {

enum class Level {
    Light,
    Medium,
    Heavy
};

/// 播放一次分级提示音。轻量级、短促，可被连续调用。
void play(Level level);

/// 是否开启“减弱动效”（减少位移与脉冲）。
bool reduceMotion();
void setReduceMotion(bool on);

} // namespace Feedback