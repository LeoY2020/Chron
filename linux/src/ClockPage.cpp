#include "ClockPage.h"

#include <QFont>
#include <QFontMetricsF>
#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QPen>
#include <QRadialGradient>
#include <QTime>
#include <QtMath>

#include "Theme.h"

namespace {

struct SunStop {
    double hour;
    QColor top;
    QColor bottom;
    QColor ink;
};

const SunStop kSunStops[] = {
    { 0.0,  QColor(9, 11, 22),    QColor(2, 3, 8),      QColor(170, 184, 226) },
    { 5.0,  QColor(16, 16, 30),   QColor(4, 4, 12),     QColor(196, 186, 220) },
    { 7.0,  QColor(48, 32, 52),   QColor(12, 12, 26),   QColor(255, 214, 168) },
    { 12.0, QColor(26, 44, 78),   QColor(10, 16, 34),   QColor(255, 246, 232) },
    { 16.0, QColor(30, 44, 70),   QColor(10, 15, 30),   QColor(255, 238, 214) },
    { 19.0, QColor(62, 36, 50),   QColor(14, 10, 22),   QColor(255, 190, 140) },
    { 21.0, QColor(24, 20, 38),   QColor(6, 6, 16),     QColor(206, 190, 224) },
    { 24.0, QColor(9, 11, 22),    QColor(2, 3, 8),      QColor(170, 184, 226) },
};
const int kSunStopCount = int(sizeof(kSunStops) / sizeof(kSunStops[0]));

SunStop sunAt(double hour) {
    hour = qBound(0.0, hour, 24.0);
    for (int i = 0; i < kSunStopCount - 1; ++i) {
        if (hour <= kSunStops[i + 1].hour) {
            const SunStop &a = kSunStops[i];
            const SunStop &b = kSunStops[i + 1];
            const double span = qMax(0.001, b.hour - a.hour);
            const double k = Theme::smoothstep((hour - a.hour) / span);
            SunStop result;
            result.hour = hour;
            result.top = Theme::mix(a.top, b.top, k);
            result.bottom = Theme::mix(a.bottom, b.bottom, k);
            result.ink = Theme::mix(a.ink, b.ink, k);
            return result;
        }
    }
    return kSunStops[kSunStopCount - 1];
}

QString twoDigits(int value) {
    return QStringLiteral("%1").arg(value, 2, 10, QLatin1Char('0'));
}

} // namespace

ClockPage::ClockPage() {
    const Settings &settings = Settings::instance();
    m_style = settings.clockStyle();
    m_color = QColor(QStringLiteral("#") + settings.clockColorHex());
}

QStringList ClockPage::styleNames() const {
    return { QStringLiteral("指针"), QStringLiteral("沉浸"), QStringLiteral("全屏沉浸"),
             QStringLiteral("七段码"), QStringLiteral("太阳") };
}

void ClockPage::setStyle(Settings::ClockStyle style) {
    m_style = style;
    Settings::instance().setClockStyle(style);
}

void ClockPage::setColor(const QColor &color) {
    m_color = color;
    Settings::instance().setClockColorHex(color.name().mid(1).toUpper());
}

bool ClockPage::isImmersive() const {
    return m_style == Settings::ClockStyle::Immersive;
}

void ClockPage::paint(QPainter &painter, const QRectF &rect, double now) {
    Q_UNUSED(now)
    painter.fillRect(rect, Theme::bg());
    switch (m_style) {
    case Settings::ClockStyle::Analog:    paintAnalog(painter, rect); break;
    case Settings::ClockStyle::Plain:     paintPlain(painter, rect); break;
    case Settings::ClockStyle::Immersive: paintImmersive(painter, rect); break;
    case Settings::ClockStyle::SevenSegment: paintSeven(painter, rect); break;
    case Settings::ClockStyle::Sun:       paintSun(painter, rect); break;
    }
}

void ClockPage::paintAnalog(QPainter &painter, const QRectF &rect) const {
    const QTime time = QTime::currentTime();
    const double seconds = time.second() + time.msec() / 1000.0;
    const double minutes = time.minute() + seconds / 60.0;
    const double hours = (time.hour() % 12) + minutes / 60.0;

    const double radius = qMin(rect.width(), rect.height()) * 0.37;
    const QPointF center = rect.center();

    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);

    painter.setPen(QPen(Theme::withAlpha(m_color, 20), 1.0));
    painter.setBrush(Qt::NoBrush);
    painter.drawEllipse(center, radius, radius);

    for (int i = 0; i < 60; ++i) {
        const bool major = i % 5 == 0;
        painter.save();
        painter.translate(center);
        painter.rotate(i * 6.0);
        painter.setPen(QPen(Theme::withAlpha(m_color, major ? 64 : 22), major ? 1.6 : 1.0,
                            Qt::SolidLine, Qt::RoundCap));
        painter.drawLine(QPointF(0, -radius), QPointF(0, -radius + (major ? 14.0 : 6.0)));
        painter.restore();
    }

    auto drawHand = [&](double angle, double length, double width, QColor color) {
        painter.save();
        painter.translate(center);
        painter.rotate(angle);
        painter.setPen(QPen(color, width, Qt::SolidLine, Qt::RoundCap));
        painter.drawLine(QPointF(0, length * 0.12), QPointF(0, -length));
        painter.restore();
    };

    drawHand(hours * 30.0, radius * 0.52, 5.0, Theme::withAlpha(m_color, 235));
    drawHand(minutes * 6.0, radius * 0.76, 3.4, Theme::withAlpha(m_color, 235));
    drawHand(seconds * 6.0, radius * 0.86, 1.4, Theme::warm());

    painter.setPen(Qt::NoPen);
    painter.setBrush(m_color);
    painter.drawEllipse(center, 4.5, 4.5);
    painter.setBrush(Theme::bg());
    painter.drawEllipse(center, 2.0, 2.0);
    painter.restore();
}

void ClockPage::paintPlain(QPainter &painter, const QRectF &rect) const {
    const QTime time = QTime::currentTime();
    const QString text = twoDigits(time.hour()) + QStringLiteral(":") + twoDigits(time.minute());
    const double width = rect.width() * 0.74;
    const qreal size = qMin(rect.height() * 0.24,
                            Theme::fitFontSize(text, Theme::rounded(200.0), width, rect.height() * 0.24));
    painter.setFont(Theme::rounded(size, QFont::DemiBold));
    painter.setPen(m_color);
    painter.drawText(QRectF(rect.center().x() - width / 2.0, rect.center().y() - rect.height() * 0.14,
                            width, rect.height() * 0.28),
                     Qt::AlignCenter, text);

    const QString secs = twoDigits(time.second());
    painter.setFont(Theme::rounded(size * 0.16, QFont::Medium));
    painter.setPen(Theme::dim());
    painter.drawText(QRectF(rect.center().x() - width / 2.0, rect.center().y() + rect.height() * 0.12,
                            width, 30.0),
                     Qt::AlignCenter, secs);
}

void ClockPage::paintImmersive(QPainter &painter, const QRectF &rect) const {
    const QTime time = QTime::currentTime();
    const QString text = twoDigits(time.hour()) + QStringLiteral(":") + twoDigits(time.minute());
    const QRectF area = rect.adjusted(24.0, 24.0, -24.0, -24.0);
    QFont base = Theme::condensed(240.0, QFont::Bold);
    const QFontMetricsF metrics(base);
    const qreal size = qMin(area.width() / qMax<qreal>(1.0, metrics.horizontalAdvance(text) / 240.0),
                            area.height() / qMax<qreal>(1.0, metrics.height() / 240.0));
    painter.setFont(Theme::condensed(size, QFont::Bold));
    painter.setPen(m_color);
    painter.drawText(area, Qt::AlignCenter, text);
}

void ClockPage::drawSegmentDigit(QPainter &painter, const QRectF &rect, int digit,
                                 const QColor &on, const QColor &off) const {
    static const int segments[10] = {
        0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F
    };
    const int mask = digit >= 0 && digit <= 9 ? segments[digit] : 0;
    const double x0 = rect.left();
    const double x1 = rect.center().x() - rect.width() * 0.06;
    const double x2 = rect.right();
    const double y0 = rect.top();
    const double y1 = rect.center().y() - rect.height() * 0.03;
    const double y2 = rect.bottom();
    const double thickness = qMax(2.0, rect.width() * 0.10);
    const double penWidth = thickness * 0.72;

    struct Segment { int bit; QPointF a; QPointF b; };
    const Segment list[7] = {
        { 0x01, QPointF(x0 + thickness, y0), QPointF(x1, y0) },          // a
        { 0x02, QPointF(x2, y0 + thickness), QPointF(x2, y1) },          // b
        { 0x04, QPointF(x2, y1), QPointF(x2, y2 - thickness) },          // c
        { 0x08, QPointF(x0 + thickness, y2), QPointF(x1, y2) },          // d
        { 0x10, QPointF(x0, y1), QPointF(x0, y2 - thickness) },          // e
        { 0x20, QPointF(x0, y0 + thickness), QPointF(x0, y1) },          // f
        { 0x40, QPointF(x0, y1), QPointF(x1, y1) },                      // g
    };

    painter.save();
    painter.setBrush(Qt::NoBrush);
    for (const Segment &segment : list) {
        const bool active = (mask & segment.bit) != 0;
        painter.setPen(QPen(active ? on : off, penWidth, Qt::SolidLine, Qt::RoundCap));
        painter.drawLine(segment.a, segment.b);
    }
    painter.restore();
}

void ClockPage::paintSeven(QPainter &painter, const QRectF &rect) const {
    const QTime time = QTime::currentTime();
    const int digits[4] = { time.hour() / 10, time.hour() % 10, time.minute() / 10, time.minute() % 10 };

    const double digitWidth = qMin(rect.width() * 0.13, rect.height() * 0.16);
    const double digitHeight = digitWidth * 1.9;
    const double gap = digitWidth * 0.34;
    const double colonGap = digitWidth * 0.50;
    const double total = digitWidth * 4.0 + gap * 2.0 + colonGap * 2.0;
    double x = rect.center().x() - total / 2.0;
    const double y = rect.center().y() - digitHeight / 2.0;

    const QColor on = Theme::mix(m_color, QColor(255, 170, 90), 0.35);
    const QColor off = Theme::withAlpha(m_color, 14);

    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);
    for (int i = 0; i < 4; ++i) {
        drawSegmentDigit(painter, QRectF(x, y, digitWidth, digitHeight), digits[i], on, off);
        x += digitWidth;
        if (i == 1) {
            painter.setPen(Qt::NoPen);
            painter.setBrush(on);
            x += colonGap;
            const double dotSize = digitWidth * 0.16;
            painter.drawEllipse(QPointF(x, y + digitHeight * 0.32), dotSize, dotSize);
            painter.drawEllipse(QPointF(x, y + digitHeight * 0.70), dotSize, dotSize);
            x += colonGap;
        } else if (i < 3) {
            x += gap;
        }
    }
    painter.restore();

    painter.setFont(Theme::rounded(12.0, QFont::Medium));
    painter.setPen(Theme::faint());
    painter.drawText(QRectF(rect.left(), y + digitHeight + 26.0, rect.width(), 24.0),
                     Qt::AlignCenter, QStringLiteral("CHRON"));
}

void ClockPage::paintSun(QPainter &painter, const QRectF &rect) const {
    const QTime time = QTime::currentTime();
    const double hour = time.hour() + time.minute() / 60.0 + time.second() / 3600.0;
    const SunStop palette = sunAt(hour);

    QLinearGradient background(rect.topLeft(), rect.bottomLeft());
    background.setColorAt(0.0, palette.top);
    background.setColorAt(1.0, palette.bottom);
    painter.fillRect(rect, background);

    const double warmth = qBound(0.0, 1.0 - qAbs(hour - 7.2) / 5.0, 1.0)
                        + qBound(0.0, 1.0 - qAbs(hour - 19.0) / 4.0, 1.0);
    if (warmth > 0.01) {
        QRadialGradient glow(QPointF(rect.center().x(), rect.bottom() * 0.86),
                             rect.width() * 0.72);
        QColor warmGlow(255, 174, 108);
        warmGlow.setAlpha(int(qMin(1.0, warmth) * 46.0));
        glow.setColorAt(0.0, warmGlow);
        glow.setColorAt(1.0, QColor(0, 0, 0, 0));
        painter.fillRect(rect, glow);
    }

    const QString text = twoDigits(time.hour()) + QStringLiteral(":") + twoDigits(time.minute());
    const double width = rect.width() * 0.76;
    const qreal size = Theme::fitFontSize(text, Theme::rounded(200.0), width, rect.height() * 0.20);
    painter.setFont(Theme::rounded(size, QFont::DemiBold));
    painter.setPen(palette.ink);
    painter.drawText(QRectF(rect.center().x() - width / 2.0,
                            rect.center().y() - rect.height() * 0.12,
                            width, rect.height() * 0.24),
                     Qt::AlignCenter, text);
}