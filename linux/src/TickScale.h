#pragma once

#include <QColor>
#include <QPointF>
#include <QRectF>
#include <QtGlobal>

class QPainter;

/// 番茄钟的时间刻度：拖动刻度改变上方时间，经过刻度时给出轻反馈。
class TickScale {
public:
    TickScale();

    void setRange(int minimum, int maximum);
    void setValue(int value);
    int value() const;

    /// appear 为 0–1 的展开进度，用于就地展开动画。
    void paint(QPainter &painter, const QRectF &rect, double appear, const QColor &ink) const;
    bool press(const QPointF &pos, const QRectF &rect);
    void move(const QPointF &pos, const QRectF &rect);
    void release(const QPointF &pos, const QRectF &rect);
    void tick(double dt);
    void reset();

private:
    double pixelsPerUnit(const QRectF &rect) const;
    void setValueInternal(int value, bool haptic);

    int m_minimum = 1;
    int m_maximum = 90;
    double m_value = 25.0;
    double m_target = 25.0;
    bool m_dragging = false;
    double m_lastX = 0.0;
    double m_travel = 0.0;
    double m_velocity = 0.0;
};