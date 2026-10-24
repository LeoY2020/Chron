#pragma once

#include <QtGlobal>
#include <cmath>

/// 统一的动效工具：与 iOS / macOS 端的缓动曲线保持一致。
namespace Motion {

/// cubic-bezier(0.4, 0, 0.2, 1)：先求解 x 方向参数，再取 y。
inline double bezier(double x) {
    x = qBound(0.0, x, 1.0);
    double lo = 0.0;
    double hi = 1.0;
    for (int i = 0; i < 22; ++i) {
        const double mid = (lo + hi) * 0.5;
        const double bx = 1.2 * mid * (1 - mid) * (1 - mid)
                       + 0.6 * mid * mid * (1 - mid)
                       + mid * mid * mid;
        if (bx < x) lo = mid; else hi = mid;
    }
    const double t = (lo + hi) * 0.5;
    return 3 * t * t * (1 - t) + t * t * t;
}

inline double easeOutCubic(double x) {
    x = qBound(0.0, x, 1.0);
    return 1.0 - std::pow(1.0 - x, 3.0);
}

/// 轻微回弹，用于“缩小进入设置态”。
inline double easeOutBack(double x) {
    x = qBound(0.0, x, 1.0);
    const double c1 = 0.9;
    const double c3 = c1 + 1.0;
    const double p = x - 1.0;
    return 1.0 + c3 * p * p * p + c1 * p * p;
}

inline double clamp01(double x) { return qBound(0.0, x, 1.0); }

/// 单值补间：from → to，按给定时长与缓动推进。
class Tween {
public:
    void set(double from, double to, double duration, bool overshoot = false) {
        m_from = from;
        m_to = to;
        m_duration = qMax(0.001, duration);
        m_elapsed = 0.0;
        m_value = from;
        m_active = true;
        m_overshoot = overshoot;
    }

    void animateTo(double to, double duration, bool overshoot = false) {
        set(m_value, to, duration, overshoot);
    }

    void step(double dt) {
        if (!m_active) return;
        m_elapsed += dt;
        const double p = clamp01(m_elapsed / m_duration);
        const double eased = m_overshoot ? easeOutBack(p) : bezier(p);
        m_value = m_from + (m_to - m_from) * eased;
        if (p >= 1.0) {
            m_value = m_to;
            m_active = false;
        }
    }

    void snap(double value) {
        m_value = value;
        m_from = value;
        m_to = value;
        m_elapsed = m_duration;
        m_active = false;
    }

    double value() const { return m_value; }
    bool active() const { return m_active; }

private:
    double m_from = 0.0;
    double m_to = 0.0;
    double m_duration = 0.3;
    double m_elapsed = 0.3;
    double m_value = 0.0;
    bool m_active = false;
    bool m_overshoot = false;
};

} // namespace Motion