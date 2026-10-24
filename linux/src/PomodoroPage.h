#pragma once

#include <QColor>
#include <QPointF>
#include <QRectF>
#include <QString>
#include <QtGlobal>

#include "Motion.h"
#include "Page.h"
#include "TickScale.h"

/// 番茄钟页：橙色专注氛围、下拉总结、刻度调时。
class PomodoroPage : public Page {
public:
    enum class Phase { Idle, Focus, Break };

    PomodoroPage();

    void paint(QPainter &painter, const QRectF &rect, double now) override;
    bool press(const QPointF &pos, const QRectF &rect) override;
    void move(const QPointF &pos, const QRectF &rect) override;
    void release(const QPointF &pos, const QRectF &rect) override;
    void tick(double dt) override;
    void reset() override;
    void cancel() override;

private:
    enum class Adjust { None, Focus, Break };

    QString formatted(double seconds) const;
    QString phaseTitle() const;
    QColor accent() const;
    QRectF timeRect(const QRectF &rect) const;
    QRectF controlRect(int index, const QRectF &rect) const;
    QRectF chipRect(int index, const QRectF &rect) const;
    QRectF scaleRect(const QRectF &rect) const;
    QRectF summaryRect(const QRectF &rect) const;

    void paintFocusBackground(QPainter &painter, const QRectF &rect) const;
    void paintControls(QPainter &painter, const QRectF &rect) const;
    void paintChips(QPainter &painter, const QRectF &rect) const;
    void paintAdjust(QPainter &painter, const QRectF &rect) const;
    void paintSummary(QPainter &painter, const QRectF &rect) const;

    void startPhase(Phase phase);
    void toggleRun();
    void abandon();
    void finishPhase();
    void beginAdjust(Adjust target);
    void endAdjust();

    Phase m_phase = Phase::Idle;
    bool m_running = false;
    double m_remaining = 25 * 60.0;
    double m_focusTotal = 25 * 60.0;
    double m_breakTotal = 5 * 60.0;

    Adjust m_adjust = Adjust::None;
    TickScale m_scale;
    bool m_scaleDragging = false;

    bool m_pulling = false;
    double m_pullStartY = 0.0;
    bool m_summaryOpen = false;
    Motion::Tween m_pull;

    double m_pulse = 0.0;
};