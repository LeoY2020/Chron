#include "StyleBar.h"

#include <QFont>
#include <QLinearGradient>
#include <QPainter>
#include <QPainterPath>
#include <QPen>
#include <QtMath>

#include "Theme.h"

namespace {

const char *kPalette[] = { "F5F5F7", "FFA35C", "E8C07A", "9CC4FF", "FF8E9B" };
const int kPaletteCount = 5;
const int kThickness[] = { 4, 10, 18 };
const int kThicknessCount = 3;

const double kSidePad = 18.0;
const double kTopPad = 16.0;
const double kChipHeight = 46.0;
const double kGap = 16.0;
const double kBottomPad = 16.0;
const double kEditorHeight = 96.0;

QColor colorFromHex(const QString &hex) {
    QColor color;
    color.setNamedColor(QStringLiteral("#") + hex);
    return color.isValid() ? color : QColor(245, 245, 247);
}

} // namespace

QColor StyleBar::paletteColor(int index) {
    if (index < 0 || index >= kPaletteCount) return QColor(245, 245, 247);
    return colorFromHex(kPalette[index]);
}

int StyleBar::thicknessValue(int index) {
    if (index < 0 || index >= kThicknessCount) return 10;
    return kThickness[index];
}

void StyleBar::setStyles(const QStringList &names) {
    m_styles = names;
}

void StyleBar::setCurrent(int index) {
    m_current = qMax(0, index);
}

void StyleBar::setProgress(double progress) {
    m_progress = Motion::clamp01(progress);
}

void StyleBar::setEditing(bool on) {
    if (m_editing == on) return;
    m_editing = on;
    m_editTween.set(editorProgress(), on ? 1.0 : 0.0, 0.26);
}

void StyleBar::setShowThickness(bool on) {
    m_showThickness = on;
}

void StyleBar::setColor(const QColor &color) {
    m_color = color;
}

void StyleBar::setThickness(int thickness) {
    m_thickness = thickness;
}

void StyleBar::tick(double dt) {
    m_editTween.step(dt);
}

QRectF StyleBar::panelRect(const QRectF &rect) const {
    const double width = qMin(rect.width() - 72.0, 560.0);
    const double editor = editorProgress() * kEditorHeight;
    double height = kTopPad + kChipHeight + kBottomPad;
    if (editor > 0.5) height += kGap + editor;
    const double bottomInset = 26.0;
    const double slide = (1.0 - m_progress) * (height + 56.0);
    const double left = rect.center().x() - width / 2.0;
    const double bottom = rect.bottom() - bottomInset + slide;
    return QRectF(left, bottom - height, width, height);
}

QRectF StyleBar::chipRect(int index, const QRectF &rect) const {
    const QRectF panel = panelRect(rect);
    const int count = qMax(1, int(m_styles.size()));
    const double innerWidth = panel.width() - kSidePad * 2.0;
    const double gap = 8.0;
    const double width = (innerWidth - gap * (count - 1)) / count;
    const double top = panel.bottom() - kBottomPad - kChipHeight;
    return QRectF(panel.left() + kSidePad + index * (width + gap), top, width, kChipHeight);
}

QRectF StyleBar::swatchRect(int index, const QRectF &rect) const {
    const QRectF panel = panelRect(rect);
    const double spacing = 44.0;
    const double total = spacing * (kPaletteCount - 1);
    const double centerX = panel.center().x();
    const double y = panel.top() + kTopPad + 26.0;
    return QRectF(centerX - total / 2.0 + index * spacing - 13.0, y - 13.0, 26.0, 26.0);
}

QRectF StyleBar::thicknessRect(int index, const QRectF &rect) const {
    const QRectF panel = panelRect(rect);
    const double spacing = 58.0;
    const double total = spacing * (kThicknessCount - 1);
    const double centerX = panel.center().x();
    const double y = panel.top() + kTopPad + 70.0;
    return QRectF(centerX - total / 2.0 + index * spacing - 15.0, y - 15.0, 30.0, 30.0);
}

StyleBar::Result StyleBar::hit(const QPointF &pos, const QRectF &rect, int *index) const {
    if (index) *index = -1;
    if (m_progress < 0.5) return Result::None;
    const QRectF panel = panelRect(rect);
    if (!panel.contains(pos)) return Result::None;

    for (int i = 0; i < int(m_styles.size()); ++i) {
        if (chipRect(i, rect).adjusted(-2, -2, 2, 2).contains(pos)) {
            if (index) *index = i;
            return i == m_current ? Result::ToggleEdit : Result::Style;
        }
    }

    if (editorProgress() > 0.6) {
        for (int i = 0; i < kPaletteCount; ++i) {
            if (swatchRect(i, rect).contains(pos)) {
                if (index) *index = i;
                return Result::Color;
            }
        }
        if (m_showThickness) {
            for (int i = 0; i < kThicknessCount; ++i) {
                if (thicknessRect(i, rect).contains(pos)) {
                    if (index) *index = i;
                    return Result::Thickness;
                }
            }
        }
    }
    return Result::None;
}

void StyleBar::paint(QPainter &painter, const QRectF &rect) const {
    if (m_progress <= 0.001) return;

    const QRectF panel = panelRect(rect);
    painter.save();
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setOpacity(m_progress);

    // 底部遮罩，让面板浮于内容之上而不显生硬。
    QLinearGradient scrim(QPointF(rect.left(), rect.bottom() - 220.0), rect.bottomLeft());
    scrim.setColorAt(0.0, QColor(0, 0, 0, 0));
    scrim.setColorAt(0.7, QColor(0, 0, 0, 130));
    scrim.setColorAt(1.0, QColor(0, 0, 0, 190));
    painter.fillRect(QRectF(rect.left(), rect.bottom() - 220.0, rect.width(), 220.0), scrim);

    QPainterPath shape;
    shape.addRoundedRect(panel, 24.0, 24.0);
    painter.setPen(QPen(QColor(255, 255, 255, 26), 1.0));
    painter.setBrush(QColor(24, 24, 27, 236));
    painter.drawPath(shape);

    // 样式胶囊。
    for (int i = 0; i < int(m_styles.size()); ++i) {
        const QRectF chip = chipRect(i, rect);
        const bool active = i == m_current;
        QPainterPath chipPath;
        chipPath.addRoundedRect(chip, 15.0, 15.0);
        painter.setPen(Qt::NoPen);
        painter.setBrush(active ? QColor(255, 255, 255, 28) : QColor(255, 255, 255, 7));
        painter.drawPath(chipPath);

        QFont font = Theme::rounded(13.0, active ? QFont::DemiBold : QFont::Medium);
        painter.setFont(font);
        painter.setPen(active ? Theme::ink() : Theme::dim());
        painter.drawText(chip, Qt::AlignCenter, m_styles.value(i));
    }

    const double editor = editorProgress();
    if (editor > 0.02) {
        painter.setOpacity(m_progress * Motion::clamp01(editor));

        for (int i = 0; i < kPaletteCount; ++i) {
            const QRectF swatch = swatchRect(i, rect);
            const QColor color = colorFromHex(kPalette[i]);
            const bool active = color.rgb() == m_color.rgb();
            QPainterPath path;
            path.addEllipse(swatch);
            painter.setPen(Qt::NoPen);
            painter.setBrush(color);
            painter.drawPath(path);
            if (active) {
                painter.setPen(QPen(Theme::ink(), 1.6));
                painter.setBrush(Qt::NoBrush);
                painter.drawEllipse(swatch.adjusted(-4.0, -4.0, 4.0, 4.0));
            }
        }

        if (m_showThickness) {
            painter.setFont(Theme::rounded(11.0, QFont::Medium));
            for (int i = 0; i < kThicknessCount; ++i) {
                const QRectF cell = thicknessRect(i, rect);
                const bool active = kThickness[i] == m_thickness;
                painter.setPen(QPen(active ? Theme::ink() : Theme::faint(),
                                    kThickness[i] / 3.0 + 1.0));
                painter.setBrush(Qt::NoBrush);
                painter.drawEllipse(cell.adjusted(4.0, 4.0, -4.0, -4.0));
            }
        }
    }

    painter.restore();
}