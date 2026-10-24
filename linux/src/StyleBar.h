#pragma once

#include <QColor>
#include <QPointF>
#include <QRectF>
#include <QStringList>
#include <QtGlobal>

#include "Motion.h"

class QPainter;

/// 底部样式栏：样式切换 + 就地编辑（颜色 / 圆环粗细）。
class StyleBar {
public:
    enum class Result { None, Style, ToggleEdit, Color, Thickness };

    static constexpr int ColorCount = 5;
    static constexpr int ThicknessCount = 3;
    static QColor paletteColor(int index);
    static int thicknessValue(int index);

    void setStyles(const QStringList &names);
    void setCurrent(int index);
    int current() const { return m_current; }

    void setProgress(double progress);
    double progress() const { return m_progress; }

    void setEditing(bool on);
    bool editing() const { return m_editing; }

    void setShowThickness(bool on);
    void setColor(const QColor &color);
    QColor color() const { return m_color; }
    void setThickness(int thickness);
    int thickness() const { return m_thickness; }

    /// 返回当前悬停/命中项索引；None 表示点在面板外。
    Result hit(const QPointF &pos, const QRectF &rect, int *index = nullptr) const;

    void paint(QPainter &painter, const QRectF &rect) const;
    void tick(double dt);

private:
    double editorProgress() const { return m_editTween.value(); }
    QRectF panelRect(const QRectF &rect) const;
    QRectF chipRect(int index, const QRectF &rect) const;
    QRectF swatchRect(int index, const QRectF &rect) const;
    QRectF thicknessRect(int index, const QRectF &rect) const;

    QStringList m_styles;
    int m_current = 0;
    double m_progress = 0.0;
    bool m_editing = false;
    bool m_showThickness = true;
    QColor m_color = QColor(QStringLiteral("#F5F5F7"));
    int m_thickness = 10;
    Motion::Tween m_editTween;
};