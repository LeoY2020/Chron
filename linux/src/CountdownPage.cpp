#include "CountdownPage.h"

#include <QConicalGradient>
#include <QFont>
#include <QFontMetricsF>
#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QPen>
#include <QtMath>

#include <cmath>

#include "Feedback.h"
#include "Theme.h"

namespace {
const double kCornerInset = 26.0;
}

CountdownPage::CountdownPage() {
    const Settings &settings = Settings::instance();
    m_style = settings.countdownStyle();
    m_color = QColor(QStringLiteral("#") + settings.countdownColorHex());
    m_thickness = settings.ringThickness();
    m_total = settings.countdownSeconds();
    m_remaining = m_total;
    m_wheel.setTotal(int(m_total));
}

QStringList CountdownPage::styleNames() const {
    return { QStringLiteral("圆环"), QStringLiteral("扇形"), QStringLiteral("指针"),
             QStringLiteral("沉浸"), QStringLiteral("全屏沉浸") };
}

void CountdownPage::setStyle(Settings::CountdownStyle style) {
    m_style = style;
    Settings::instance().setCountdownStyle(style);
}

void CountdownPage::setColor(const QColor &color) {
    m_color = color;
    Settings::instance().setCountdownColorHex(color.name().mid(1).toUpper());
}

void CountdownPage::setThickness(int thickness) {
    m_thickness = qBound(2, thickness, 28);
    Settings::instance().setRingThickness(m_thickness);
}

bool CountdownPage::isImmersive() const {
    return m_style == Settings::CountdownStyle::Immersive;
}

QString CountdownPage::formatted(double seconds) const {
    const int total = qMax(0, int(std::ceil(seconds - 0.0001)));
    const int hours = total / 3600;
    const int minutes = (total % 3600) / 60;
    const int secs = total % 60;
    if (hours > 0) {
        return QStringLiteral("%1:%2:%3")
            .arg(hours)
            .arg(minutes, 2, 10, QLatin1Char('0'))
            .arg(secs, 2, 10, QLatin1Char('0'));
    }
    return QStringLiteral("%1:%2")
        .arg(minutes, 2, 10, QLatin1Char('0'))
        .arg(secs, 2, 10, QLatin1Char('0'));
}

QRectF CountdownPage::timeRect(const QRectF &rect) const {
    const double height = rect.height() * 0.30;
    return QRectF(rect.left() + rect.width() * 0.08,
                  rect.center().y() - height / 2.0,
                  rect.width() * 0.84, height);
}

QRectF CountdownPage::controlRect(int index, const QRectF &rect) const {
    const double size = 56.0;
    const double gap = 40.0;
    const double centerX = rect.center().x();
    const double y = rect.bottom() - 92.0;
    if (index == 0) return QRectF(centerX - gap / 2.0 - size, y - size / 2.0, size, size);
    return QRectF(centerX + gap / 2.0, y - size / 2.0, size, size);
}

QRectF CountdownPage::wheelRect(const QRectF &rect) const {
    const double width = qMin(rect.width() - 80.0, 340.0);
    return QRectF(rect.center().x() - width / 2.0, rect.center().y() - 78.0, width, 156.0);
}

void CountdownPage::paint(QPainter &painter, const QRectF &rect, double now) {
    Q_UNUSED(now)
    painter.fillRect(rect, Theme::bg());

    const double progress = m_total > 0.0 ? Motion::clamp01(m_remaining / m_total) : 0.0;

    switch (m_style) {
    case Settings::CountdownStyle::Ring:
        paintRing(painter, rect, progress);
        break;
    case Settings::CountdownStyle::Sector:
        paintSector(painter, rect, progress);
        break;
    case Settings::CountdownStyle::Dial:
        paintDial(painter, rect, progress);
        break;
    case Settings::CountdownStyle::Plain:
        paintPlain(painter, rect, progress);
        break;
    case Settings::CountdownStyle::Immersive:
        paintImmersive(painter, rect);
        break;
    }

    if (m_setting) {
        painter.setFont(Theme::rounded(12.0, QFont::Medium));
        painter.setPen(Theme::faint());
        painter.drawText(QRectF(rect.left(), wheelRect(rect).bottom() + 18.0, rect.width(), 22.0),
                         Qt::AlignCenter, QStringLiteral("时      分      秒"));
        painter.drawText(QRectF(rect.left(), rect.bottom() - 54.0, rect.width(), 22.0),
                         Qt::AlignCenter, QStringLiteral("点击空白处完成"));
        m_wheel.paint(painter, wheelRect(rect), m_color);
    } else {
        paintControls(painter, rect);
    }

    if (m_pulse > 0.001) {
        painter.save();
        painter.setOpacity(m_pulse * 0.55);
        painter.setPen(QPen(m_color, 2.0));
        painter.setBrush(Qt::NoBrush);
        const double radius = qMin(rect.width(), rect.height()) * (0.30 + (1.0 - m_pulse) * 0.22);
        painter.drawEllipse(rect.center(), radius, radius);
        painter.restore();
    }
}

void CountdownPage::paintRing(QPainter &painter, const QRectF &rect, double progress) const {
    const double radius = qMin(rect.width(), rect.height()) * 0.31;
    const QRectF circle(rect.center().x() - radius, rect.center().y() - radius, radius * 2.0, radius * 2.0);

    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setPen(QPen(Theme::withAlpha(m_color, 26), m_thickness));
    painter.setBrush(Qt::NoBrush);
    painter.drawEllipse(circle);

    if (progress > 0.0005) {
        painter.setPen(QPen(m_color, m_thickness, Qt::SolidLine, Qt::RoundCap));
        painter.drawArc(circle, int(90 * 16), int(-progress * 360.0 * 16));
    }
    painter.restore();

    const QRectF digits(rect.center().x() - radius * 0.78, rect.center().y() - radius * 0.34,
                        radius * 1.56, radius * 0.68);
    painter.setFont(Theme::rounded(Theme::fitFontSize(formatted(m_remaining), Theme::rounded(radius * 0.46),
                                                      digits.width(), digits.height() * 0.9),
                                   QFont::DemiBold));
    painter.setPen(m_color);
    painter.drawText(digits, Qt::AlignCenter, formatted(m_remaining));
}

void CountdownPage::paintSector(QPainter &painter, const QRectF &rect, double progress) const {
    const double radius = qMax(rect.width(), rect.height()) * 0.78;
    QPainterPath path;
    path.moveTo(rect.center());
    path.arcTo(QRectF(rect.center().x() - radius, rect.center().y() - radius, radius * 2.0, radius * 2.0),
               90.0, -progress * 360.0);
    path.closeSubpath();

    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);
    QConicalGradient gradient(rect.center(), 90.0);
    QColor warmYellow(255, 196, 92, 74);
    QColor orange(255, 132, 58, 74);
    gradient.setColorAt(0.0, orange);
    gradient.setColorAt(0.48, warmYellow);
    gradient.setColorAt(0.52, warmYellow);
    gradient.setColorAt(1.0, orange);
    painter.setPen(Qt::NoPen);
    painter.setBrush(gradient);
    painter.drawPath(path);
    painter.restore();

    painter.setFont(Theme::rounded(Theme::fitFontSize(formatted(m_remaining), Theme::rounded(120.0),
                                                      rect.width() * 0.8, rect.height() * 0.24),
                                   QFont::DemiBold));
    painter.setPen(m_color);
    painter.drawText(timeRect(rect), Qt::AlignCenter, formatted(m_remaining));
}

void CountdownPage::paintDial(QPainter &painter, const QRectF &rect, double progress) const {
    const double radius = qMin(rect.width(), rect.height()) * 0.34;
    const QPointF center = rect.center();

    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);
    const int ticks = 60;
    for (int i = 0; i < ticks; ++i) {
        const double angle = i * 360.0 / ticks;
        const double length = (i % 5 == 0) ? 12.0 : 6.0;
        painter.save();
        painter.translate(center);
        painter.rotate(angle);
        painter.setPen(QPen(Theme::withAlpha(m_color, 30 + int(40 * (i % 5 == 0))), 1.2));
        painter.drawLine(QPointF(0, -radius), QPointF(0, -radius + length));
        painter.restore();
    }

    painter.rotate(progress * 360.0);
    painter.setPen(QPen(m_color, 2.4, Qt::SolidLine, Qt::RoundCap));
    painter.drawLine(center, QPointF(center.x(), center.y() - radius * 0.86));
    painter.setPen(Qt::NoPen);
    painter.setBrush(m_color);
    painter.drawEllipse(center, 4.0, 4.0);
    painter.restore();

    painter.setFont(Theme::rounded(Theme::fitFontSize(formatted(m_remaining), Theme::rounded(120.0),
                                                      rect.width() * 0.62, rect.height() * 0.20),
                                   QFont::DemiBold));
    painter.setPen(m_color);
    painter.drawText(timeRect(rect), Qt::AlignCenter, formatted(m_remaining));
}

void CountdownPage::paintPlain(QPainter &painter, const QRectF &rect, double progress) const {
    const QRectF area = rect.adjusted(rect.width() * 0.08, 0, -rect.width() * 0.08, 0);
    const qreal size = Theme::fitFontSize(formatted(m_remaining), Theme::rounded(160.0),
                                          area.width(), rect.height() * 0.26);
    painter.setFont(Theme::rounded(size, QFont::DemiBold));
    painter.setPen(m_color);
    painter.drawText(timeRect(rect), Qt::AlignCenter, formatted(m_remaining));

    const double lineWidth = rect.width() * 0.30;
    const double y = timeRect(rect).bottom() + 34.0;
    painter.setPen(QPen(Theme::withAlpha(m_color, 22), 1.0));
    painter.drawLine(QPointF(rect.center().x() - lineWidth / 2.0, y),
                     QPointF(rect.center().x() + lineWidth / 2.0, y));
    painter.setPen(QPen(Theme::withAlpha(m_color, 130), 1.6, Qt::SolidLine, Qt::RoundCap));
    painter.drawLine(QPointF(rect.center().x() - lineWidth / 2.0, y),
                     QPointF(rect.center().x() - lineWidth / 2.0 + lineWidth * progress, y));
}

void CountdownPage::paintImmersive(QPainter &painter, const QRectF &rect) const {
    const QString text = formatted(m_remaining);
    const QRectF area = rect.adjusted(kCornerInset, kCornerInset, -kCornerInset, -kCornerInset);
    QFont base = Theme::condensed(240.0, QFont::Bold);
    const QFontMetricsF metrics(base);
    const qreal naturalWidth = metrics.horizontalAdvance(text);
    const qreal naturalHeight = metrics.height();
    const qreal size = qMin(area.width() / qMax<qreal>(1.0, naturalWidth / 240.0),
                            area.height() / qMax<qreal>(1.0, naturalHeight / 240.0));
    painter.setFont(Theme::condensed(size, QFont::Bold));
    painter.setPen(m_color);
    painter.drawText(area, Qt::AlignCenter, text);
}

void CountdownPage::paintControls(QPainter &painter, const QRectF &rect) const {
    const double opacity = (m_running || m_finished) ? 0.42 : 0.62;
    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);

    for (int i = 0; i < 2; ++i) {
        const QRectF cell = controlRect(i, rect);
        painter.setPen(QPen(Theme::withAlpha(Theme::ink(), 26), 1.0));
        painter.setBrush(Qt::NoBrush);
        painter.drawEllipse(cell);

        painter.save();
        painter.setOpacity(opacity);
        painter.setPen(Qt::NoPen);
        painter.setBrush(Theme::ink());
        const QPointF center = cell.center();
        if (i == 0) {
            if (m_running) {
                const double barWidth = 4.2;
                const double barHeight = 17.0;
                painter.drawRoundedRect(QRectF(center.x() - 8.0 - barWidth / 2.0,
                                               center.y() - barHeight / 2.0, barWidth, barHeight), 2.0, 2.0);
                painter.drawRoundedRect(QRectF(center.x() + 8.0 - barWidth / 2.0,
                                               center.y() - barHeight / 2.0, barWidth, barHeight), 2.0, 2.0);
            } else {
                QPainterPath triangle;
                triangle.moveTo(center.x() - 6.0, center.y() - 9.0);
                triangle.lineTo(center.x() + 9.0, center.y());
                triangle.lineTo(center.x() - 6.0, center.y() + 9.0);
                triangle.closeSubpath();
                painter.drawPath(triangle);
            }
        } else {
            painter.setPen(QPen(Theme::ink(), 1.8, Qt::SolidLine, Qt::RoundCap));
            painter.setBrush(Qt::NoBrush);
            const QRectF arc(center.x() - 10.0, center.y() - 10.0, 20.0, 20.0);
            painter.drawArc(arc, int(40 * 16), int(280 * 16));
            QPainterPath arrow;
            arrow.moveTo(center.x() + 5.0, center.y() - 11.0);
            arrow.lineTo(center.x() + 10.0, center.y() - 8.0);
            arrow.lineTo(center.x() + 6.0, center.y() - 4.0);
            arrow.closeSubpath();
            painter.setPen(Qt::NoPen);
            painter.setBrush(Theme::ink());
            painter.drawPath(arrow);
        }
        painter.restore();
    }
    painter.restore();
}

void CountdownPage::toggleRun() {
    if (m_finished) {
        m_finished = false;
        m_remaining = m_total;
        m_running = true;
    } else {
        m_running = !m_running;
    }
    Feedback::play(Feedback::Level::Medium);
}

void CountdownPage::resetTimer() {
    m_running = false;
    m_finished = false;
    m_remaining = m_total;
    Feedback::play(Feedback::Level::Light);
}

void CountdownPage::finish() {
    m_remaining = 0.0;
    m_running = false;
    m_finished = true;
    m_pulse = 1.0;
    Feedback::play(Feedback::Level::Heavy);
}

void CountdownPage::commitDuration() {
    const int seconds = qBound(1, m_wheel.total(), 24 * 3600 - 1);
    Settings::instance().setCountdownSeconds(seconds);
    m_total = seconds;
    if (!m_running) {
        m_remaining = m_total;
        m_finished = false;
    }
}

void CountdownPage::enterSetting() {
    m_setting = true;
    m_wheel.setTotal(int(m_total));
    m_wheelDragging = false;
    Feedback::play(Feedback::Level::Light);
}

void CountdownPage::tick(double dt) {
    if (m_pulse > 0.0) m_pulse = qMax(0.0, m_pulse - dt * 0.85);
    if (m_setting) m_wheel.tick(dt);
    if (!m_running || m_setting) return;
    m_remaining -= dt;
    if (m_remaining <= 0.0) finish();
}

void CountdownPage::reset() {
    m_setting = false;
    m_wheelDragging = false;
    m_timeTapPending = false;
    m_wheel.reset();
}

void CountdownPage::cancel() {
    m_timeTapPending = false;
    m_wheelDragging = false;
}

bool CountdownPage::press(const QPointF &pos, const QRectF &rect) {
    m_pressPos = pos;
    m_pressRect = rect;

    if (m_setting) {
        if (m_wheel.press(pos, wheelRect(rect))) {
            m_wheelDragging = true;
            return true;
        }
        m_setting = false;
        commitDuration();
        return true;
    }

    if (controlRect(0, rect).adjusted(-6, -6, 6, 6).contains(pos)) {
        toggleRun();
        return true;
    }
    if (controlRect(1, rect).adjusted(-6, -6, 6, 6).contains(pos)) {
        resetTimer();
        return true;
    }
    if (!m_running && timeRect(rect).adjusted(0, -20.0, 0, 40.0).contains(pos)) {
        // 不消费本次按压：长按仍可进入样式设置，点击则在抬起时进入调时。
        m_timeTapPending = true;
        return false;
    }
    m_timeTapPending = false;
    return false;
}

void CountdownPage::move(const QPointF &pos, const QRectF &rect) {
    if (m_wheelDragging && m_setting) {
        m_wheel.move(pos, wheelRect(rect));
        return;
    }
    if (m_timeTapPending) {
        if ((pos - m_pressPos).manhattanLength() > 10.0) m_timeTapPending = false;
    }
}

void CountdownPage::release(const QPointF &pos, const QRectF &rect) {
    if (m_wheelDragging && m_setting) {
        m_wheel.release(pos, wheelRect(rect));
        m_wheelDragging = false;
        return;
    }
    if (m_timeTapPending && !m_setting) {
        m_timeTapPending = false;
        enterSetting();
    }
}