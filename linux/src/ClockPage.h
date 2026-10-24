#pragma once

#include <QColor>
#include <QRectF>
#include <QStringList>
#include <QtGlobal>

#include "Motion.h"
#include "Page.h"
#include "Settings.h"

/// 全屏时钟页：指针 / 沉浸 / 全屏沉浸 / 七段码 / 太阳。
class ClockPage : public Page {
public:
    ClockPage();

    void paint(QPainter &painter, const QRectF &rect, double now) override;
    bool isImmersive() const override;

    void setStyle(Settings::ClockStyle style);
    Settings::ClockStyle style() const { return m_style; }
    QStringList styleNames() const;

    void setColor(const QColor &color);
    QColor color() const { return m_color; }

private:
    void paintAnalog(QPainter &painter, const QRectF &rect) const;
    void paintPlain(QPainter &painter, const QRectF &rect) const;
    void paintImmersive(QPainter &painter, const QRectF &rect) const;
    void paintSeven(QPainter &painter, const QRectF &rect) const;
    void paintSun(QPainter &painter, const QRectF &rect) const;

    void drawSegmentDigit(QPainter &painter, const QRectF &rect, int digit,
                          const QColor &on, const QColor &off) const;

    Settings::ClockStyle m_style = Settings::ClockStyle::Plain;
    QColor m_color = QColor(245, 245, 247);
};