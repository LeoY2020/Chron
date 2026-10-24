#include "DurationWheel.h"

#include <QFont>
#include <QFontMetricsF>
#include <QLinearGradient>
#include <QPen>
#include <QPainter>
#include <QPainterPath>
#include <QtMath>

#include "Feedback.h"
#include "Theme.h"

DurationWheel::DurationWheel() {
    setTotal(300);
}



void DurationWheel::setTotal(int seconds) {
    seconds = qBound(0, seconds, 24 * 3600 - 1);
    m_columns[0].maximum = 23;
    m_columns[1].maximum = 59;
    m_columns[2].maximum = 59;
    const int hours = seconds / 3600;
    const int minutes = (seconds % 3600) / 60;
    const int secs = seconds % 60;
    const int values[3] = { hours, minutes, secs };
    for (int i = 0; i < 3; ++i) {
        m_columns[i].offset = values[i];
        m_columns[i].target = values[i];
        m_columns[i].dragging = false;
        m_columns[i].velocity = 0.0;
    }
}

int DurationWheel::total() const {
    return valueAt(0) * 3600 + valueAt(1) * 60 + valueAt(2);
}

int DurationWheel::valueAt(int column) const {
    if (column < 0 || column > 2) return 0;
    const int value = qRound(m_columns[column].offset);
    return qBound(0, value, m_columns[column].maximum);
}

int DurationWheel::itemHeight(const QRectF &rect) const {
    return int(qBound(30.0, rect.height() / 5.0, 62.0));
}

QRectF DurationWheel::columnRect(int index, const QRectF &rect) const {
    const double gap = 10.0;
    const double columnWidth = qMin(96.0, (rect.width() - gap * 2.0) / 3.0);
    const double totalWidth = columnWidth * 3.0 + gap * 2.0;
    const double left = rect.center().x() - totalWidth / 2.0;
    return QRectF(left + index * (columnWidth + gap), rect.top(), columnWidth, rect.height());
}

int DurationWheel::columnAt(const QPointF &pos, const QRectF &rect) const {
    for (int i = 0; i < 3; ++i) {
        if (columnRect(i, rect).adjusted(-2, 0, 2, 0).contains(pos)) return i;
    }
    return -1;
}

void DurationWheel::paint(QPainter &painter, const QRectF &rect, const QColor &ink) const {
    const int height = itemHeight(rect);
    const double centerY = rect.center().y();

    for (int i = 0; i < 3; ++i) {
        const QRectF column = columnRect(i, rect);
        painter.save();
        painter.setClipRect(column.adjusted(0, 0, 0, 0));

        const int first = int(qFloor(m_columns[i].offset)) - 2;
        const int last = int(qCeil(m_columns[i].offset)) + 2;
        for (int value = first; value <= last; ++value) {
            if (value < 0 || value > m_columns[i].maximum) continue;
            const double distance = qAbs(value - m_columns[i].offset);
            if (distance > 2.6) continue;
            const double falloff = qBound(0.0, 1.0 - distance / 2.2, 1.0);
            const double y = centerY + (value - m_columns[i].offset) * height;
            const double scale = 0.72 + 0.28 * falloff;
            QFont font = Theme::rounded(height * 0.62 * scale, QFont::DemiBold);
            painter.setFont(font);
            QColor color = Theme::mix(Theme::faint(), ink, falloff * falloff);
            painter.setPen(color);
            const QString text = QStringLiteral("%1").arg(value, 2, 10, QLatin1Char('0'));
            painter.drawText(QRectF(column.left(), y - height / 2.0, column.width(), height),
                             Qt::AlignCenter, text);
        }
        painter.restore();
    }

    // 选中态：极细的横向提示线，克制但明确。
    const double lineWidth = rect.width() * 0.34;
    painter.setPen(QPen(Theme::withAlpha(ink, 34), 1.0));
    painter.drawLine(QPointF(rect.center().x() - lineWidth / 2.0, centerY + height / 2.0),
                     QPointF(rect.center().x() + lineWidth / 2.0, centerY + height / 2.0));
    painter.drawLine(QPointF(rect.center().x() - lineWidth / 2.0, centerY - height / 2.0),
                     QPointF(rect.center().x() + lineWidth / 2.0, centerY - height / 2.0));

    // 顶部 / 底部渐隐，避免生硬裁切。
    QLinearGradient fadeTop(rect.topLeft(), QPointF(rect.left(), rect.top() + height * 1.4));
    fadeTop.setColorAt(0.0, Theme::bg());
    fadeTop.setColorAt(1.0, QColor(8, 8, 10, 0));
    painter.fillRect(QRectF(rect.left(), rect.top(), rect.width(), height * 1.4), fadeTop);

    QLinearGradient fadeBottom(QPointF(rect.left(), rect.bottom() - height * 1.4), rect.bottomLeft());
    fadeBottom.setColorAt(0.0, QColor(8, 8, 10, 0));
    fadeBottom.setColorAt(1.0, Theme::bg());
    painter.fillRect(QRectF(rect.left(), rect.bottom() - height * 1.4, rect.width(), height * 1.4), fadeBottom);
}

bool DurationWheel::press(const QPointF &pos, const QRectF &rect) {
    const int column = columnAt(pos, rect);
    if (column < 0) return false;
    Column &c = m_columns[column];
    c.dragging = true;
    c.dragStartOffset = c.offset;
    c.lastY = pos.y();
    c.velocity = 0.0;
    c.travel = 0.0;
    c.lastTick = qRound(c.offset);
    c.target = c.offset;
    return true;
}

void DurationWheel::move(const QPointF &pos, const QRectF &rect) {
    const int height = itemHeight(rect);
    for (int i = 0; i < 3; ++i) {
        Column &c = m_columns[i];
        if (!c.dragging) continue;
        const double delta = pos.y() - c.lastY;
        c.lastY = pos.y();
        c.travel += qAbs(delta);
        c.velocity = delta / height;
        double next = c.offset - delta / height;
        if (next < 0.0) next = -qMin(0.32, -next * 0.28);
        if (next > c.maximum) next = c.maximum + qMin(0.32, (next - c.maximum) * 0.28);
        c.offset = next;
        c.target = next;
        const int current = qRound(c.offset);
        if (current != c.lastTick) {
            c.lastTick = current;
            if (current >= 0 && current <= c.maximum) Feedback::play(Feedback::Level::Light);
        }
    }
}

void DurationWheel::release(const QPointF &pos, const QRectF &rect) {
    const int height = itemHeight(rect);
    for (int i = 0; i < 3; ++i) {
        Column &c = m_columns[i];
        if (!c.dragging) continue;
        c.dragging = false;
        if (c.travel < 5.0) {
            // 轻点某一行：直接吸附到该行。
            const QRectF column = columnRect(i, rect);
            const double tapped = c.offset + (column.center().y() - pos.y()) / height;
            snapColumn(i, qBound(0.0, double(qRound(tapped)), double(c.maximum)), 0.18);
        } else {
            const double inertia = qBound(-1.8, c.velocity * 1.1, 1.8);
            const double projected = qBound(0.0, c.offset + inertia, double(c.maximum));
            snapColumn(i, qRound(projected), 0.22);
        }
        c.velocity = 0.0;
    }
}

void DurationWheel::snapColumn(int index, double value, double duration) {
    Column &c = m_columns[index];
    c.target = qBound(0.0, value, double(c.maximum));
    Q_UNUSED(duration)
}

void DurationWheel::tick(double dt) {
    m_time += dt;
    double fastest = 0.0;
    for (int i = 0; i < 3; ++i) {
        Column &c = m_columns[i];
        if (c.dragging) continue;
        const double diff = c.target - c.offset;
        if (qAbs(diff) < 0.0008) {
            if (c.offset != c.target) {
                c.offset = c.target;
                if (c.lastTick != qRound(c.offset)) {
                    c.lastTick = qRound(c.offset);
                    Feedback::play(Feedback::Level::Light);
                }
            }
            continue;
        }
        const double step = diff * qMin(1.0, dt * 15.0);
        c.offset += step;
        fastest = qMax(fastest, qAbs(diff));
    }
    Q_UNUSED(fastest)
}

void DurationWheel::reset() {
    for (int i = 0; i < 3; ++i) {
        m_columns[i].offset = m_columns[i].target;
        m_columns[i].dragging = false;
        m_columns[i].velocity = 0.0;
    }
}

bool DurationWheel::settling() const {
    for (int i = 0; i < 3; ++i) {
        if (m_columns[i].dragging) return true;
        if (qAbs(m_columns[i].target - m_columns[i].offset) > 0.001) return true;
    }
    return false;
}