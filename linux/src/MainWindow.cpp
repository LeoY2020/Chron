#include "MainWindow.h"

#include <QApplication>
#include <QDateTime>
#include <QFont>
#include <QKeyEvent>
#include <QMouseEvent>
#include <QPainter>
#include <QPainterPath>
#include <QPen>
#include <QTimer>
#include <QWheelEvent>
#include <QtMath>

#include <cmath>

#include "ClockPage.h"
#include "CountdownPage.h"
#include "Feedback.h"
#include "PomodoroPage.h"
#include "Settings.h"
#include "Theme.h"

namespace {
const double kLongPressMs = 460.0;
const double kShrinkScale = 0.93;
}

MainWindow::MainWindow(QWidget *parent) : QWidget(parent) {
    setWindowTitle(QStringLiteral("Chron"));
    setMinimumSize(460, 520);
    resize(960, 680);
    setFocusPolicy(Qt::StrongFocus);
    setAttribute(Qt::WA_OpaquePaintEvent, true);
    setMouseTracking(false);

    m_countdown = new CountdownPage();
    m_pomodoro = new PomodoroPage();
    m_clock = new ClockPage();

    m_shrinkTween.snap(0.0);
    m_pagingTween.snap(0.0);

    m_frame = new QTimer(this);
    m_frame->setTimerType(Qt::PreciseTimer);
    m_frame->setInterval(16);
    connect(m_frame, &QTimer::timeout, this, &MainWindow::onFrame);
    m_frame->start();
    m_clock.start();

    m_longPress = new QTimer(this);
    m_longPress->setSingleShot(true);
    connect(m_longPress, &QTimer::timeout, this, [this] {
        if (!m_pressed || m_shrink || m_pressConsumed) return;
        if (m_page != 0 && m_page != 2) return;
        m_longPressFired = true;
        openStyleBar();
    });

    configureStyleBar();
}

Page *MainWindow::pageAt(int index) const {
    switch (index) {
    case 0: return m_countdown;
    case 1: return m_pomodoro;
    case 2: return m_clock;
    default: return nullptr;
    }
}

Page *MainWindow::currentPage() const {
    return pageAt(m_page);
}

void MainWindow::configureStyleBar() {
    if (m_page == 0) {
        m_styleBar.setStyles(m_countdown->styleNames());
        m_styleBar.setCurrent(int(m_countdown->style()));
        m_styleBar.setShowThickness(true);
        m_styleBar.setColor(m_countdown->color());
        m_styleBar.setThickness(m_countdown->thickness());
    } else if (m_page == 2) {
        m_styleBar.setStyles(m_clock->styleNames());
        m_styleBar.setCurrent(int(m_clock->style()));
        m_styleBar.setShowThickness(false);
        m_styleBar.setColor(m_clock->color());
    }
}

void MainWindow::openStyleBar() {
    if (m_shrink) return;
    m_shrink = true;
    m_styleBar.setEditing(false);
    configureStyleBar();
    m_shrinkTween.set(m_shrinkTween.value(), 1.0, 0.36, true);
    if (currentPage()) currentPage()->cancel();
    Feedback::play(Feedback::Level::Medium);
    update();
}

void MainWindow::closeStyleBar() {
    if (!m_shrink) return;
    m_shrink = false;
    m_styleBar.setEditing(false);
    m_shrinkTween.animateTo(0.0, 0.28);
    Feedback::play(Feedback::Level::Light);
    update();
}

void MainWindow::handleStyleBar(const QPointF &pos) {
    int index = -1;
    const StyleBar::Result result = m_styleBar.hit(pos, rect(), &index);
    switch (result) {
    case StyleBar::Result::Style:
        if (index < 0) break;
        if (m_page == 0) {
            m_countdown->setStyle(Settings::CountdownStyle(index));
        } else if (m_page == 2) {
            m_clock->setStyle(Settings::ClockStyle(index));
        }
        m_styleBar.setCurrent(index);
        Feedback::play(Feedback::Level::Light);
        break;
    case StyleBar::Result::ToggleEdit:
        m_styleBar.setEditing(!m_styleBar.editing());
        Feedback::play(Feedback::Level::Light);
        break;
    case StyleBar::Result::Color:
        if (index < 0) break;
        m_styleBar.setColor(StyleBar::paletteColor(index));
        if (m_page == 0) m_countdown->setColor(m_styleBar.color());
        else if (m_page == 2) m_clock->setColor(m_styleBar.color());
        Feedback::play(Feedback::Level::Light);
        break;
    case StyleBar::Result::Thickness:
        if (index < 0) break;
        m_styleBar.setThickness(StyleBar::thicknessValue(index));
        if (m_page == 0) m_countdown->setThickness(m_styleBar.thickness());
        Feedback::play(Feedback::Level::Light);
        break;
    case StyleBar::Result::None:
    default:
        closeStyleBar();
        break;
    }
    update();
}

void MainWindow::onFrame() {
    double dt = m_clock.restart() / 1000.0;
    dt = qBound(0.0, dt, 0.05);

    for (int i = 0; i < 3; ++i) {
        if (Page *page = pageAt(i)) page->tick(dt);
    }
    m_styleBar.tick(dt);

    m_shrinkTween.step(dt);
    m_styleBar.setProgress(Motion::clamp01(m_shrinkTween.value()));
    if (m_pagingTween.active()) {
        m_pagingTween.step(dt);
        m_dragOffset = m_pagingTween.value();
    }
    update();
}

double MainWindow::offsetFor(int index) const {
    return (index - m_page) * width() + m_dragOffset;
}

void MainWindow::paintEvent(QPaintEvent *event) {
    Q_UNUSED(event)
    QPainter painter(this);
    painter.setRenderHint(QPainter::Antialiasing, true);
    painter.setRenderHint(QPainter::TextAntialiasing, true);
    painter.fillRect(rect(), Qt::black);

    const double shrink = Motion::clamp01(m_shrinkTween.value());
    const double pageScale = 1.0 - (1.0 - kShrinkScale) * shrink;
    const double now = double(QDateTime::currentMSecsSinceEpoch()) / 1000.0;
    const QRectF base = rect();

    for (int i = 0; i < 3; ++i) {
        const double x = offsetFor(i);
        if (qAbs(x) > width() * 1.05) continue;
        Page *page = pageAt(i);
        if (!page) continue;

        const double t = qBound(0.0, qAbs(x) / qMax(1.0, double(width())), 1.0);
        const double scale = pageScale * (1.0 - 0.05 * t);
        QRectF target(base.x() + x, base.y(), base.width(), base.height());

        painter.save();
        painter.setClipRect(base);
        painter.setOpacity(1.0 - 0.4 * t);
        painter.translate(target.center());
        painter.scale(scale, scale);
        painter.translate(-target.center());
        page->paint(painter, target, now);
        painter.restore();
    }

    // 页面指示器：极简三个点，沉浸态隐藏。
    if (shrink < 0.02) {
        const bool immersive = currentPage() && currentPage()->isImmersive();
        if (!immersive) {
            painter.save();
            for (int i = 0; i < 3; ++i) {
                const double radius = i == m_page ? 2.8 : 2.0;
                const QColor color = i == m_page ? Theme::withAlpha(Theme::ink(), 130)
                                                 : Theme::withAlpha(Theme::ink(), 46);
                painter.setPen(Qt::NoPen);
                painter.setBrush(color);
                painter.drawEllipse(QPointF(width() / 2.0 + (i - 1) * 18.0, height() - 26.0),
                                    radius, radius);
            }
            painter.restore();
        }
    }

    m_styleBar.paint(painter, base);
}

void MainWindow::mousePressEvent(QMouseEvent *event) {
    const QPointF pos = event->position();
    m_pressPos = pos;
    m_lastPos = pos;
    m_lastMoveMs = QDateTime::currentMSecsSinceEpoch();
    m_pressed = true;
    m_paging = false;
    m_longPressFired = false;
    m_dragVelocity = 0.0;

    if (event->button() != Qt::LeftButton) return;

    if (m_shrink) {
        m_pressConsumed = true;
        handleStyleBar(pos);
        return;
    }

    m_dragOffset = m_pagingTween.value();
    m_pagingTween.snap(m_dragOffset);
    Page *page = currentPage();
    m_pressPage = page;
    m_pressConsumed = page ? page->press(pos, rect()) : false;
    m_longPress->start(int(kLongPressMs));
}

void MainWindow::mouseMoveEvent(QMouseEvent *event) {
    const QPointF pos = event->position();
    if (!m_pressed) return;
    if (m_shrink) return;

    const double dx = pos.x() - m_pressPos.x();
    const double dy = pos.y() - m_pressPos.y();

    if (!m_longPressFired && !m_pressConsumed && !m_paging) {
        if (qAbs(dx) > 9.0 && qAbs(dx) > qAbs(dy)) {
            m_paging = true;
            m_longPress->stop();
        }
    }

    if (m_paging) {
        m_dragOffset = dx;
        if ((m_page == 0 && dx > 0) || (m_page == 2 && dx < 0)) {
            m_dragOffset = dx * 0.32;
        }
        const qint64 nowMs = QDateTime::currentMSecsSinceEpoch();
        const qint64 elapsed = qMax<qint64>(1, nowMs - m_lastMoveMs);
        m_dragVelocity = (pos.x() - m_lastPos.x()) / double(elapsed) * 1000.0;
        m_lastPos = pos;
        m_lastMoveMs = nowMs;
    } else if (m_pressConsumed) {
        if (Page *page = currentPage()) page->move(pos, rect());
        if ((pos - m_pressPos).manhattanLength() > 9.0) m_longPress->stop();
    } else if ((pos - m_pressPos).manhattanLength() > 9.0) {
        m_longPress->stop();
    }
    update();
}

void MainWindow::mouseReleaseEvent(QMouseEvent *event) {
    const QPointF pos = event->position();
    const bool fired = m_longPressFired;
    const bool paging = m_paging;
    Page *page = m_pressPage;
    m_pressed = false;
    m_pressConsumed = false;
    m_pressPage = nullptr;
    m_paging = false;
    m_longPressFired = false;
    m_longPress->stop();

    if (event->button() != Qt::LeftButton) return;

    if (m_shrink || fired) {
        update();
        return;
    }

    if (paging) {
        settlePaging();
        return;
    }

    if (page) page->release(pos, rect());
}

void MainWindow::settlePaging() {
    const double widthPx = qMax(1.0, double(width()));
    int target = m_page;
    if (qAbs(m_dragOffset) > widthPx * 0.18 || qAbs(m_dragVelocity) > 900.0) {
        if (m_dragOffset < 0.0 && m_page < 2) target = m_page + 1;
        else if (m_dragOffset > 0.0 && m_page > 0) target = m_page - 1;
    }
    if (target != m_page) {
        m_dragOffset += (target - m_page) * widthPx;
        m_page = target;
        if (Page *page = currentPage()) page->reset();
    }
    m_pagingTween.set(m_dragOffset, 0.0, 0.30);
    Feedback::play(Feedback::Level::Light);
    update();
}

void MainWindow::switchPage(int index) {
    index = qBound(0, index, 2);
    if (index == m_page) return;
    m_dragOffset = (m_page - index) * width();
    m_page = index;
    m_pagingTween.set(m_dragOffset, 0.0, 0.30);
    if (Page *page = currentPage()) page->reset();
    Feedback::play(Feedback::Level::Light);
    update();
}

void MainWindow::wheelEvent(QWheelEvent *event) {
    if (m_shrink) {
        event->accept();
        return;
    }
    const int delta = event->angleDelta().x() != 0 ? event->angleDelta().x() : event->angleDelta().y();
    if (delta == 0) return;
    if (qAbs(delta) < 40) {
        event->accept();
        return;
    }
    switchPage(m_page + (delta < 0 ? 1 : -1));
    event->accept();
}

void MainWindow::keyPressEvent(QKeyEvent *event) {
    switch (event->key()) {
    case Qt::Key_Left:
    case Qt::Key_Up:
        if (!m_shrink) switchPage(m_page - 1);
        break;
    case Qt::Key_Right:
    case Qt::Key_Down:
        if (!m_shrink) switchPage(m_page + 1);
        break;
    case Qt::Key_Escape:
        if (m_shrink) closeStyleBar();
        break;

    case Qt::Key_F11:
        isFullScreen() ? showNormal() : showFullScreen();
        break;
    default:
        QWidget::keyPressEvent(event);
        break;
    }
}