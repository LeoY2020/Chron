#pragma once

#include <QPointF>
#include <QRectF>
#include <QtGlobal>

class QPainter;

/// 全屏页面基类：单画布立即模式渲染，便于整体缩放与分页过渡。
class Page {
public:
    virtual ~Page() = default;

    /// 在给定矩形内绘制页面内容（rect 即页面全尺寸）。
    virtual void paint(QPainter &painter, const QRectF &rect, double now) = 0;

    virtual bool press(const QPointF &pos, const QRectF &rect) {
        Q_UNUSED(pos)
        Q_UNUSED(rect)
        return false;
    }
    virtual void move(const QPointF &pos, const QRectF &rect) {
        Q_UNUSED(pos)
        Q_UNUSED(rect)
    }
    virtual void release(const QPointF &pos, const QRectF &rect) {
        Q_UNUSED(pos)
        Q_UNUSED(rect)
    }

    /// 每帧推进，dt 为秒。
    virtual void tick(double dt) { Q_UNUSED(dt) }

    /// 页面重新出现时复位瞬时状态。
    virtual void reset() {}

    /// 取消进行中的瞬时输入（例如长按进入设置态时）。
    virtual void cancel() {}

    /// 是否应隐藏页面指示器（沉浸态）。
    virtual bool isImmersive() const { return false; }
};