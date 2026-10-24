#include "PomodoroPage.h"

#include <QFont>
#include <QFontMetricsF>
#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QPen>
#include <QStringList>
#include <QRadialGradient>
#include <QtMath>

#include <cmath>

#include "Feedback.h"
#include "Settings.h"
#include "Theme.h"

namespace {

QString minuteText(int minutes) {
    return QStringLiteral("%1 分钟").arg(minutes);
}

QString durationText(int seconds) {
    if (seconds >= 3600) {
        return QStringLiteral("%1 小时 %2 分").arg(seconds / 3600).arg((seconds % 3600) / 60);
    }
    if (seconds >= 60) return QStringLiteral("%1 分钟").arg(seconds / 60);
    return QStringLiteral("%1 秒").arg(seconds);
}

} // namespace

PomodoroPage::PomodoroPage() {
    const Settings &settings = Settings::instance();
    m_focusTotal = settings.focusSeconds();
    m_breakTotal = settings.breakSeconds();
    m_remaining = m_focusTotal;
    m_scale.setRange(1, 90);
    m_scale.setValue(int(m_focusTotal / 60));
}

QString PomodoroPage::formatted(double seconds) const {
    const int total = qMax(0, int(std::ceil(seconds - 0.0001)));
    return QStringLiteral("%1:%2").arg(total / 60, 2, 10, QLatin1Char('0'))
                                  .arg(total % 60, 2, 10, QLatin1Char('0'));
}

QString PomodoroPage::phaseTitle() const {
    switch (m_phase) {
    case Phase::Idle:  return QStringLiteral("准备专注");
    case Phase::Focus: return m_running ? QStringLiteral("专注中") : QStringLiteral("已暂停");
    case Phase::Break: return QStringLiteral("休息");
    }
    return QString();
}

QColor PomodoroPage::accent() const {
    if (m_phase == Phase::Break) return Theme::mix(Theme::warm(), QColor(150, 205, 188), 0.62);
    return Theme::warm();
}

QRectF PomodoroPage::timeRect(const QRectF &rect) const {
    const double height = rect.height() * 0.26;
    return QRectF(rect.left() + rect.width() * 0.10, rect.center().y() - height / 2.0,
                  rect.width() * 0.80, height);
}

QRectF PomodoroPage::controlRect(int index, const QRectF &rect) const {
    const double size = 56.0;
    const double gap = 40.0;
    const double centerX = rect.center().x();
    const double y = rect.bottom() - 92.0;
    if (index == 0) return QRectF(centerX - gap / 2.0 - size, y - size / 2.0, size, size);
    return QRectF(centerX + gap / 2.0, y - size / 2.0, size, size);
}

QRectF PomodoroPage::chipRect(int index, const QRectF &rect) const {
    const double width = 132.0;
    const double height = 34.0;
    const double gap = 12.0;
    const double centerX = rect.center().x();
    const double y = rect.bottom() - 166.0;
    if (index == 0) return QRectF(centerX - gap / 2.0 - width, y - height / 2.0, width, height);
    return QRectF(centerX + gap / 2.0, y - height / 2.0, width, height);
}

QRectF PomodoroPage::scaleRect(const QRectF &rect) const {
    const double width = qMin(rect.width() * 0.72, 520.0);
    return QRectF(rect.center().x() - width / 2.0, rect.center().y() + 40.0, width, 96.0);
}

QRectF PomodoroPage::summaryRect(const QRectF &rect) const {
    const double height = qMin(rect.height() * 0.46, 440.0);
    const double offset = (1.0 - Motion::clamp01(m_pull.value())) * (-height - 40.0);
    return QRectF(rect.left(), rect.top() + offset, rect.width(), height);
}

void PomodoroPage::paintFocusBackground(QPainter &painter, const QRectF &rect) const {
    painter.fillRect(rect, Theme::bg());
    const QColor tone = accent();
    QRadialGradient glow(QPointF(rect.center().x(), rect.center().y() + rect.height() * 0.10),
                         rect.width() * 0.85);
    QColor inner = tone;
    inner.setAlpha(m_phase == Phase::Break ? 16 : 30);
    glow.setColorAt(0.0, inner);
    glow.setColorAt(1.0, QColor(0, 0, 0, 0));
    painter.fillRect(rect, glow);
}

void PomodoroPage::paint(QPainter &painter, const QRectF &rect, double now) {
    Q_UNUSED(now)
    paintFocusBackground(painter, rect);

    if (m_adjust != Adjust::None) {
        paintAdjust(painter, rect);
        return;
    }

    const double total = m_phase == Phase::Break ? m_breakTotal : m_focusTotal;
    const double progress = total > 0.0 ? Motion::clamp01(m_remaining / total) : 0.0;

    painter.setFont(Theme::rounded(12.0, QFont::Medium));
    painter.setPen(Theme::withAlpha(accent(), 150));
    painter.drawText(QRectF(rect.left(), rect.center().y() - rect.height() * 0.22, rect.width(), 20.0),
                     Qt::AlignCenter, phaseTitle());

    const QString text = formatted(m_remaining);
    const double width = rect.width() * 0.76;
    const qreal size = Theme::fitFontSize(text, Theme::rounded(200.0), width, rect.height() * 0.22);
    painter.setFont(Theme::rounded(size, QFont::DemiBold));
    painter.setPen(Theme::mix(accent(), Theme::ink(), 0.45));
    painter.drawText(timeRect(rect), Qt::AlignCenter, text);

    // 极细进度线，跟随剩余时间。
    const double lineWidth = rect.width() * 0.34;
    const double lineY = timeRect(rect).bottom() + 24.0;
    painter.setPen(QPen(Theme::withAlpha(accent(), 26), 1.0));
    painter.drawLine(QPointF(rect.center().x() - lineWidth / 2.0, lineY),
                     QPointF(rect.center().x() + lineWidth / 2.0, lineY));
    painter.setPen(QPen(Theme::withAlpha(accent(), 160), 1.6, Qt::SolidLine, Qt::RoundCap));
    painter.drawLine(QPointF(rect.center().x() - lineWidth / 2.0, lineY),
                     QPointF(rect.center().x() - lineWidth / 2.0 + lineWidth * progress, lineY));

    if (m_phase == Phase::Idle) paintChips(painter, rect);
    paintControls(painter, rect);

    if (m_pull.value() > 0.001) paintSummary(painter, rect);

    if (m_pulse > 0.001) {
        painter.save();
        painter.setOpacity(m_pulse * 0.5);
        painter.setPen(QPen(accent(), 2.0));
        painter.setBrush(Qt::NoBrush);
        const double radius = qMin(rect.width(), rect.height()) * (0.24 + (1.0 - m_pulse) * 0.2);
        painter.drawEllipse(rect.center(), radius, radius);
        painter.restore();
    }
}

void PomodoroPage::paintControls(QPainter &painter, const QRectF &rect) const {
    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);
    for (int i = 0; i < 2; ++i) {
        const QRectF cell = controlRect(i, rect);
        painter.setPen(QPen(Theme::withAlpha(accent(), 48), 1.0));
        painter.setBrush(Qt::NoBrush);
        painter.drawEllipse(cell);

        const QPointF center = cell.center();
        painter.save();
        painter.setOpacity(0.72);
        if (i == 0) {
            painter.setPen(Qt::NoPen);
            painter.setBrush(accent());
            if (m_running) {
                painter.drawRoundedRect(QRectF(center.x() - 8.0 - 2.1, center.y() - 8.5, 4.2, 17.0), 2.0, 2.0);
                painter.drawRoundedRect(QRectF(center.x() + 8.0 - 2.1, center.y() - 8.5, 4.2, 17.0), 2.0, 2.0);
            } else {
                QPainterPath triangle;
                triangle.moveTo(center.x() - 6.0, center.y() - 9.0);
                triangle.lineTo(center.x() + 9.0, center.y());
                triangle.lineTo(center.x() - 6.0, center.y() + 9.0);
                triangle.closeSubpath();
                painter.drawPath(triangle);
            }
        } else {
            painter.setPen(QPen(Theme::withAlpha(accent(), 220), 1.7, Qt::SolidLine, Qt::RoundCap));
            painter.setBrush(Qt::NoBrush);
            painter.drawLine(QPointF(center.x() - 7.0, center.y() - 7.0),
                             QPointF(center.x() + 7.0, center.y() + 7.0));
            painter.drawLine(QPointF(center.x() + 7.0, center.y() - 7.0),
                             QPointF(center.x() - 7.0, center.y() + 7.0));
        }
        painter.restore();
    }
    painter.restore();
}

void PomodoroPage::paintChips(QPainter &painter, const QRectF &rect) const {
    const QString labels[2] = {
        QStringLiteral("专注 %1").arg(durationText(int(m_focusTotal))),
        QStringLiteral("休息 %1").arg(durationText(int(m_breakTotal)))
    };
    painter.save();
    painter.setFont(Theme::rounded(12.0, QFont::Medium));
    for (int i = 0; i < 2; ++i) {
        const QRectF chip = chipRect(i, rect);
        QPainterPath path;
        path.addRoundedRect(chip, 17.0, 17.0);
        painter.setPen(QPen(Theme::withAlpha(accent(), 30), 1.0));
        painter.setBrush(QColor(255, 255, 255, 6));
        painter.drawPath(path);
        painter.setPen(Theme::withAlpha(accent(), 190));
        painter.drawText(chip, Qt::AlignCenter, labels[i]);
    }
    painter.restore();
}

void PomodoroPage::paintAdjust(QPainter &painter, const QRectF &rect) const {
    const int minutes = m_scale.value();
    const QString text = QStringLiteral("%1").arg(minutes);
    const double width = rect.width() * 0.5;
    const qreal size = Theme::fitFontSize(text, Theme::rounded(200.0), width, rect.height() * 0.20);
    painter.setFont(Theme::rounded(size, QFont::DemiBold));
    painter.setPen(Theme::mix(accent(), Theme::ink(), 0.55));
    painter.drawText(QRectF(rect.center().x() - width / 2.0, rect.center().y() - rect.height() * 0.16,
                            width, rect.height() * 0.22),
                     Qt::AlignCenter, text);

    painter.setFont(Theme::rounded(12.0, QFont::Medium));
    painter.setPen(Theme::withAlpha(accent(), 150));
    painter.drawText(QRectF(rect.left(), rect.center().y() - rect.height() * 0.005, rect.width(), 20.0),
                     Qt::AlignCenter, m_adjust == Adjust::Focus ? QStringLiteral("专注时长 / 分钟")
                                                                : QStringLiteral("休息时长 / 分钟"));
    m_scale.paint(painter, scaleRect(rect), 1.0, accent());
}

void PomodoroPage::paintSummary(QPainter &painter, const QRectF &rect) const {
    const QRectF panel = summaryRect(rect);
    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);

    QPainterPath shape;
    shape.setFillRule(Qt::WindingFill);
    shape.addRoundedRect(panel.adjusted(-30.0, 0.0, 30.0, 0.0), 28.0, 28.0);
    shape.addRect(QRectF(panel.left() - 30.0, panel.bottom() - 30.0, panel.width() + 60.0, 50.0));
    painter.setPen(QPen(QColor(255, 255, 255, 20), 1.0));
    painter.setBrush(QColor(18, 16, 16, 246));
    painter.drawPath(shape);

    const Settings &settings = Settings::instance();
    painter.setFont(Theme::rounded(11.0, QFont::Medium));
    painter.setPen(Theme::faint());
    painter.drawText(QRectF(panel.left() + 28.0, panel.top() + 26.0, panel.width() - 56.0, 18.0),
                     Qt::AlignLeft, QStringLiteral("近期专注"));

    struct Metric { QString title; QString value; };
    const Metric metrics[2] = {
        { QStringLiteral("今日"), QStringLiteral("%1 次 · %2").arg(settings.todayCount())
              .arg(durationText(settings.todaySeconds())) },
        { QStringLiteral("本周"), QStringLiteral("%1 次 · %2").arg(settings.weekCount())
              .arg(durationText(settings.weekSeconds())) }
    };

    painter.setFont(Theme::rounded(13.0, QFont::DemiBold));
    for (int i = 0; i < 2; ++i) {
        const double top = panel.top() + 58.0 + i * 46.0;
        painter.setPen(Theme::withAlpha(accent(), 150));
        painter.drawText(QRectF(panel.left() + 28.0, top, 44.0, 36.0), Qt::AlignLeft | Qt::AlignVCenter,
                         metrics[i].title);
        painter.setPen(Theme::ink());
        painter.drawText(QRectF(panel.left() + 76.0, top, panel.width() - 110.0, 36.0),
                         Qt::AlignLeft | Qt::AlignVCenter, metrics[i].value);
    }

    // 最近七天柱状趋势：低饱和、无坐标轴。
    const QVector<int> days = settings.last7DaysMinutes();
    const double chartTop = panel.top() + 170.0;
    const double chartHeight = qMax(48.0, panel.bottom() - chartTop - 52.0);
    const double left = panel.left() + 28.0;
    const double width = panel.width() - 56.0;
    const double slot = width / 7.0;
    int peak = 1;
    for (int value : days) peak = qMax(peak, value);

    painter.setPen(Qt::NoPen);
    for (int i = 0; i < 7; ++i) {
        const double ratio = double(days.value(i)) / peak;
        const double barHeight = qMax(3.0, chartHeight * ratio);
        const double barWidth = slot * 0.34;
        const double x = left + slot * i + (slot - barWidth) / 2.0;
        const QRectF bar(x, chartTop + chartHeight - barHeight, barWidth, barHeight);
        QLinearGradient gradient(bar.topLeft(), bar.bottomLeft());
        gradient.setColorAt(0.0, Theme::withAlpha(accent(), i == 6 ? 220 : 130));
        gradient.setColorAt(1.0, Theme::withAlpha(accent(), i == 6 ? 120 : 50));
        painter.setBrush(gradient);
        QPainterPath barPath;
        barPath.addRoundedRect(bar, barWidth / 2.0, barWidth / 2.0);
        painter.drawPath(barPath);
    }

    painter.setFont(Theme::rounded(10.0, QFont::Medium));
    painter.setPen(Theme::faint());
    const QStringList labels = { QStringLiteral("一"), QStringLiteral("二"), QStringLiteral("三"),
                                 QStringLiteral("四"), QStringLiteral("五"), QStringLiteral("六"),
                                 QStringLiteral("日") };
    for (int i = 0; i < 7; ++i) {
        painter.drawText(QRectF(left + slot * i, chartTop + chartHeight + 8.0, slot, 18.0),
                         Qt::AlignCenter, labels.value(i));
    }

    painter.restore();
}

void PomodoroPage::startPhase(Phase phase) {
    m_phase = phase;
    m_remaining = phase == Phase::Break ? m_breakTotal : m_focusTotal;
    m_running = true;
    m_pulse = 1.0;
}

void PomodoroPage::toggleRun() {
    if (m_phase == Phase::Idle) {
        startPhase(Phase::Focus);
    } else {
        m_running = !m_running;
    }
    Feedback::play(Feedback::Level::Medium);
}

void PomodoroPage::abandon() {
    m_phase = Phase::Idle;
    m_running = false;
    m_focusTotal = Settings::instance().focusSeconds();
    m_breakTotal = Settings::instance().breakSeconds();
    m_remaining = m_focusTotal;
    Feedback::play(Feedback::Level::Light);
}

void PomodoroPage::finishPhase() {
    if (m_phase == Phase::Focus) {
        Settings::instance().addFocus(int(m_focusTotal));
        Feedback::play(Feedback::Level::Heavy);
        m_phase = Phase::Break;
        m_remaining = m_breakTotal;
        m_running = true;
        m_breakTotal = Settings::instance().breakSeconds();
        m_pulse = 1.0;
    } else {
        Feedback::play(Feedback::Level::Medium);
        m_phase = Phase::Idle;
        m_running = false;
        m_focusTotal = Settings::instance().focusSeconds();
        m_remaining = m_focusTotal;
        m_pulse = 0.7;
    }
}

void PomodoroPage::beginAdjust(Adjust target) {
    m_adjust = target;
    m_scaleDragging = false;
    if (target == Adjust::Focus) {
        m_scale.setRange(1, 90);
        m_scale.setValue(qMax(1, int(m_focusTotal / 60.0)));
    } else {
        m_scale.setRange(1, 30);
        m_scale.setValue(qMax(1, int(m_breakTotal / 60.0)));
    }
    m_scale.reset();
    Feedback::play(Feedback::Level::Light);
}

void PomodoroPage::endAdjust() {
    if (m_adjust == Adjust::Focus) {
        m_focusTotal = m_scale.value() * 60.0;
        Settings::instance().setFocusSeconds(int(m_focusTotal));
        if (m_phase == Phase::Idle) m_remaining = m_focusTotal;
    } else if (m_adjust == Adjust::Break) {
        m_breakTotal = m_scale.value() * 60.0;
        Settings::instance().setBreakSeconds(int(m_breakTotal));
    }
    m_adjust = Adjust::None;
    m_scaleDragging = false;
}

void PomodoroPage::tick(double dt) {
    m_pull.step(dt);
    if (m_pulse > 0.0) m_pulse = qMax(0.0, m_pulse - dt * 0.85);
    if (m_adjust != Adjust::None) {
        m_scale.tick(dt);
        return;
    }
    if (!m_running) return;
    m_remaining -= dt;
    if (m_remaining <= 0.0) finishPhase();
}

void PomodoroPage::reset() {
    m_pulling = false;
    m_scaleDragging = false;
    m_adjust = Adjust::None;
}

void PomodoroPage::cancel() {
    m_pulling = false;
    m_scaleDragging = false;
}

bool PomodoroPage::press(const QPointF &pos, const QRectF &rect) {
    if (m_summaryOpen) {
        m_summaryOpen = false;
        m_pull.animateTo(0.0, 0.30);
        Feedback::play(Feedback::Level::Light);
        return true;
    }

    if (m_adjust != Adjust::None) {
        if (m_scale.press(pos, scaleRect(rect))) {
            m_scaleDragging = true;
            return true;
        }
        endAdjust();
        return true;
    }

    if (m_pull.value() < 0.01 && pos.y() < rect.top() + 130.0) {
        m_pulling = true;
        m_pullStartY = pos.y();
        return true;
    }

    if (m_phase == Phase::Idle) {
        if (chipRect(0, rect).adjusted(-4, -4, 4, 4).contains(pos)) {
            beginAdjust(Adjust::Focus);
            return true;
        }
        if (chipRect(1, rect).adjusted(-4, -4, 4, 4).contains(pos)) {
            beginAdjust(Adjust::Break);
            return true;
        }
    }

    if (controlRect(0, rect).adjusted(-6, -6, 6, 6).contains(pos)) {
        toggleRun();
        return true;
    }
    if (controlRect(1, rect).adjusted(-6, -6, 6, 6).contains(pos)) {
        abandon();
        return true;
    }

    if (m_phase == Phase::Idle && timeRect(rect).contains(pos)) {
        beginAdjust(Adjust::Focus);
        return true;
    }
    return false;
}

void PomodoroPage::move(const QPointF &pos, const QRectF &rect) {
    if (m_scaleDragging) {
        m_scale.move(pos, scaleRect(rect));
        return;
    }
    if (!m_pulling) return;
    const double distance = pos.y() - m_pullStartY;
    const double threshold = rect.height() * 0.22;
    const double progress = Motion::clamp01(distance / threshold);
    if (progress > 0.36 && m_pull.value() <= 0.01) {
        Feedback::play(Feedback::Level::Medium);
    }
    m_pull.snap(progress * 0.92);
}

void PomodoroPage::release(const QPointF &pos, const QRectF &rect) {
    Q_UNUSED(pos)
    if (m_scaleDragging) {
        m_scale.release(pos, scaleRect(rect));
        m_scaleDragging = false;
        return;
    }
    if (!m_pulling) return;
    m_pulling = false;
    if (m_pull.value() > 0.34) {
        m_summaryOpen = true;
        m_pull.animateTo(1.0, 0.34);
        Feedback::play(Feedback::Level::Medium);
    } else {
        m_pull.animateTo(0.0, 0.24);
    }
    Q_UNUSED(rect)
}