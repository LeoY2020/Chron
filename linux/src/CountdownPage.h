#pragma once

#include <QColor>
#include <QPointF>
#include <QRectF>
#include <QString>
#include <QStringList>
#include <QtGlobal>

#include "DurationWheel.h"
#include "Motion.h"
#include "Page.h"
#include "Settings.h"

/// 倒计时页：五种样式；长按由主窗口统一处理，就地编辑由样式栏驱动。
class CountdownPage : public Page {
public:
    CountdownPage();

    void paint(QPainter &painter, const QRectF &rect, double now) override;
    bool press(const QPointF &pos, const QRectF &rect) override;
    void move(const QPointF &pos, const QRectF &rect) override;
    void release(const QPointF &pos, const QRectF &rect) override;
    void tick(double dt) override;
    void reset() override;
    void cancel() override;
    bool isImmersive() const override;

    void setStyle(Settings::CountdownStyle style);
    Settings::CountdownStyle style() const { return m_style; }
    QStringList styleNames() const;

    void setColor(const QColor &color);
    QColor color() const { return m_color; }
    void setThickness(int thickness);
    int thickness() const { return m_thickness; }

private:
    QString formatted(double seconds) const;
    QString cornerSafeText() const;
    QRectF timeRect(const QRectF &rect) const;
    QRectF controlRect(int index, const QRectF &rect) const;
    QRectF wheelRect(const QRectF &rect) const;

    void paintDigits(QPainter &painter, const QRectF &rect, const QRectF &area) const;
    void paintControls(QPainter &painter, const QRectF &rect) const;
    void paintRing(QPainter &painter, const QRectF &rect, double progress) const;
    void paintSector(QPainter &painter, const QRectF &rect, double progress) const;
    void paintDial(QPainter &painter, const QRectF &rect, double progress) const;
    void paintPlain(QPainter &painter, const QRectF &rect, double progress) const;
    void paintImmersive(QPainter &painter, const QRectF &rect) const;

    void toggleRun();
    void resetTimer();
    void finish();
    void commitDuration();
    void enterSetting();

    Settings::CountdownStyle m_style = Settings::CountdownStyle::Ring;
    QColor m_color = QColor(245, 245, 247);
    int m_thickness = 10;

    double m_total = 300.0;
    double m_remaining = 300.0;
    bool m_running = false;
    bool m_finished = false;
    bool m_setting = false;

    double m_pulse = 0.0;
    DurationWheel m_wheel;
    bool m_wheelDragging = false;
    bool m_timeTapPending = false;
    QPointF m_pressPos;
    QRectF m_pressRect;
};