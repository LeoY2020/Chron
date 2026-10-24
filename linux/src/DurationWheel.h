#pragma once

#include <QColor>
#include <QPointF>
#include <QRectF>
#include <QtGlobal>

class QPainter;

/// 倒计时时长滚轮：时 / 分 / 秒 三列，带惯性、吸附与边界回弹。
class DurationWheel {
public:
    DurationWheel();

    void setTotal(int seconds);
    int total() const;

    void paint(QPainter &painter, const QRectF &rect, const QColor &ink) const;
    bool press(const QPointF &pos, const QRectF &rect);
    void move(const QPointF &pos, const QRectF &rect);
    void release(const QPointF &pos, const QRectF &rect);
    void tick(double dt);
    void reset();

    bool settling() const;
    int valueAt(int column) const;

private:
    struct Column {
        int maximum = 0;
        double offset = 0.0;
        double target = 0.0;
        bool dragging = false;
        double dragStartOffset = 0.0;
        double lastY = 0.0;
        double velocity = 0.0;
        int lastTick = -1;
        double travel = 0.0;
    };

    int itemHeight(const QRectF &rect) const;
    QRectF columnRect(int index, const QRectF &rect) const;
    int columnAt(const QPointF &pos, const QRectF &rect) const;
    void applyOffset(int index, double value, bool haptic);
    void snapColumn(int index, double value, double duration);

    Column m_columns[3];
    double m_time = 0.0;
};