#pragma once

#include <QByteArray>
#include <QColor>
#include <QFont>
#include <QFontDatabase>
#include <QFontMetricsF>
#include <QString>
#include <QtMath>

/// 全局视觉基调：纯黑背景，克制的暖白与低饱和橙。
namespace Theme {

inline QColor bg()      { return QColor(8, 8, 10); }
inline QColor ink()     { return QColor(245, 245, 247); }
inline QColor dim()     { return QColor(128, 128, 134); }
inline QColor faint()   { return QColor(66, 66, 72); }
inline QColor warm()    { return QColor(255, 163, 92); }
inline QColor warmDeep(){ return QColor(214, 118, 62); }
inline QColor panel()   { return QColor(24, 24, 27, 240); }

/// 圆体字体族：优先使用系统内可用的原生圆体，逐级回退。
inline QString roundedFamily() {
    static const QString cached = [] {
        const QStringList families = QFontDatabase::families();
        const QStringList preferred = {
            QStringLiteral("SF Pro Rounded"),
            QStringLiteral("SF Compact Rounded"),
            QStringLiteral("Nunito"),
            QStringLiteral("Quicksand"),
            QStringLiteral("Varela Round"),
            QStringLiteral("Comfortaa"),
            QStringLiteral("Ubuntu"),
            QStringLiteral("Noto Sans"),
            QStringLiteral("DejaVu Sans")
        };
        for (const QString &name : preferred) {
            if (families.contains(name, Qt::CaseInsensitive)) return name;
        }
        return QStringLiteral("Sans Serif");
    }();
    return cached;
}

/// 圆体 + 等宽数字（tnum），字号按像素给出。
inline QFont rounded(qreal pixelSize, int weight = QFont::DemiBold) {
    QFont f(roundedFamily());
    f.setPixelSize(qMax(1, qRound(pixelSize)));
    f.setWeight(QFont::Weight(weight));
    f.setStyleHint(QFont::SansSerif);
    f.setLetterSpacing(QFont::AbsoluteSpacing, pixelSize * 0.012);
#if QT_VERSION >= QT_VERSION_CHECK(6, 7, 0)
    f.setFeature(QFontFeature(QByteArray("tnum"), 1u));
#else
    Q_UNUSED(weight)
#endif
    return f;
}

/// 沉浸样式使用的窄体圆角字：横向压缩，保持可读。
inline QFont condensed(qreal pixelSize, int weight = QFont::Bold) {
    QFont f = rounded(pixelSize, weight);
    f.setStretch(76);
    return f;
}

inline double smoothstep(double x) {
    const double c = qBound(0.0, x, 1.0);
    return c * c * (3 - 2 * c);
}

inline QColor mix(const QColor &a, const QColor &b, double k) {
    k = qBound(0.0, k, 1.0);
    return QColor(qRound(a.red()   + (b.red()   - a.red())   * k),
                  qRound(a.green() + (b.green() - a.green()) * k),
                  qRound(a.blue()  + (b.blue()  - a.blue())  * k),
                  qRound(a.alpha() + (b.alpha() - a.alpha()) * k));
}

inline QColor withAlpha(QColor c, int a) {
    c.setAlpha(qBound(0, a, 255));
    return c;
}

/// 按可用宽度把文字装入一行，返回字号。
inline qreal fitFontSize(const QString &text, const QFont &base, qreal maxWidth, qreal maxSize) {
    QFont probe = base;
    probe.setPixelSize(qMax(1, qRound(maxSize)));
    QFontMetricsF fm(probe);
    const qreal natural = qMax(1.0, fm.horizontalAdvance(text));
    return qMax(1.0, qMin(maxSize, maxSize * maxWidth / natural));
}

} // namespace Theme
