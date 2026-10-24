#include "TickScale.h"

#include <QFont>
#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QPen>
#include <QtMath>

#include "Feedback.h"
#include "Motion.h"
#include "Theme.h"

TickScale::TickScale() = default;

void TickScale::setRange(int minimum, int maximum) {
    m_minimum = qMax(1, minimum);
    m_maximum = qMax(m_minimum + 1, maximum);
    setValue(int(qBound(double(m_minimum), m_value, double(m_maximum))));
}

void TickScale::setValue(int value) {
    const double clamped = qBound(double(m_minimum), double(value), double(m_maximum));
    m_value = clamped;
    m_target = clamped;
}

int TickScale::value() const {
    return qBound(m_minimum, int(qRound(m_value)), m_maximum);
}

double TickScale::pixelsPerUnit(const QRectF &rect) const {
    return qMax(6.0, rect.width() / 46.0);
}

void TickScale::paint(QPainter &painter, const QRectF &rect, double appear, const QColor &ink) const {
    if (appear <= 0.001) return;
    const double ppu = pixelsPerUnit(rect);
    const double centerX = rect.center().x();
    const double baseline = rect.center().y();
painter.save();
    painter.setOpacity(Motion::clamp01(appear));

    // 刻度：每 1 分钟一根短刻度，每 5 分钟加长。
    const int span = int(rect.width() / ppu / 2.0) + 2;
    const int center = int(qRound(m_value));
    for (int unit = center - span; unit <= center + span; ++unit) {
        if (unit < m_minimum || unit > m_maximum) continue;
        const double x = centerX + (unit - m_value) * ppu;
        const double distance = qAbs(x - centerX) / (rect.width() / 2.0);
        if (distance > 1.05) continue;
        const double fade = qBound(0.0, 1.0 - distance, 1.0);
        const bool major = unit % 5 == 0;
        const double length = major ? 20.0 : 11.0;
        QColor color = Theme::withAlpha(ink, int(90.0 * fade + 30.0));
painter.setPen(QPen(color, major ? 1.4 : 1.0));
        painter.drawLine(QPointF(x, baseline - 6.0), QPointF(x, baseline - 6.0 + length));
    }

    // 刻度下方的基线。
    QLinearGradient line(QRectF(rect.left(), baseline + 22.0, rect.width(), 1.0).topLeft(),
                         QRectF(rect.left(), baseline + 22.0, rect.width(), 1.0).topRight());
    line.setColorAt(0.0, QColor(ink.red(), ink.green(), ink.blue(), 0));
    line.setColorAt(0.5, QColor(ink.red(), ink.green(), ink.blue(), 60));
    line.setColorAt(1.0, QColor(ink.red(), ink.green(), ink.blue(), 0));
    painter.fillRect(QRectF(rect.left() + 8.0, baseline + 21.0, rect.width() - 16.0, 1.0), line);

    // 倒三角指针。
    QPainterPath pointer;
    const double pointerTop = baseline - 18.0;
    pointer.moveTo(centerX - 6.0, pointerTop);
    pointer.lineTo(centerX + 6.0, pointerTop);
    pointer.lineTo(centerX, pointerTop + 9.0);
    pointer.closeSubpath();
    painter.setPen(Qt::NoPen);
    painter.setBrush(ink);
    painter.drawPath(pointer);

    painter.restore();
}

bool TickScale::press(const QPointF &pos, const QRectF &rect) {
    const QRectF hit = rect.adjusted(0, -60.0, 0, 40.0);
    if (!hit.contains(pos)) return false;
    m_dragging = true;
    m_lastX = pos.x();
    m_travel = 0.0;
    m_velocity = 0.0;
    m_target = m_value;
    return true;
}

void TickScale::move(const QPointF &pos, const QRectF &rect) {
    if (!m_dragging) return;
    const double delta = pos.x() - m_lastX;
    m_lastX = pos.x();
    m_travel += qAbs(delta);
    const double ppu = pixelsPerUnit(rect);
    m_velocity = -delta / ppu;
    m_value = qBound(double(m_minimum), m_value - delta / ppu, double(m_maximum));
    const int snapped = qRound(m_value);
    if (snapped != int(m_target)) {
        m_target = snapped;
        Feedback::play(Feedback::Level::Light);
    }
}

void TickScale::release(const QPointF &pos, const QRectF &rect) {
    Q_UNUSED(pos)
    Q_UNUSED(rect)
    if (!m_dragging) return;
    m_dragging = false;
    if (m_travel < 4.0) {
        m_value = double(qRound(m_value));
        m_target = m_value;
    } else {
        m_target = qBound(double(m_minimum), double(qRound(m_value + m_velocity * 1.6)), double(m_maximum));
    }
}

void TickScale::tick(double dt) {
    if (m_dragging) return;
    const double diff = m_target - m_value;
    if (qAbs(diff) < 0.0008) {
        m_value = m_target;
        return;
    }
    m_value += diff * qMin(1.0, dt * 16.0);
}

void TickScale::reset() {
    m_dragging = false;
    m_velocity = 0.0;
    m_target = m_value;
}