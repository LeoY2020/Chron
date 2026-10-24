#pragma once

#include <QElapsedTimer>
#include <QPointF>
#include <QRectF>
#include <QWidget>

#include "Motion.h"
#include "StyleBar.h"

class CountdownPage;
class PomodoroPage;
class ClockPage;
class Page;
class QTimer;

/// 单画布主窗口：三页全屏横向分页，长按缩小并唤出底部样式栏。
class MainWindow : public QWidget {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);

protected:
    void paintEvent(QPaintEvent *event) override;
    void mousePressEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;

private:
    Page *pageAt(int index) const;
    Page *currentPage() const;
    void onFrame();
    void openStyleBar();
    void closeStyleBar();
    void handleStyleBar(const QPointF &pos);
    void configureStyleBar();
    void switchPage(int index);
    void settlePaging();
    double offsetFor(int index) const;

    CountdownPage *m_countdown = nullptr;
    PomodoroPage *m_pomodoro = nullptr;
    ClockPage *m_clock = nullptr;

    StyleBar m_styleBar;
    QTimer *m_frame = nullptr;
    QTimer *m_longPress = nullptr;
    QElapsedTimer m_frameClock;

    int m_page = 0;
    bool m_shrink = false;
    Motion::Tween m_shrinkTween;
    Motion::Tween m_pagingTween;

    bool m_pressed = false;
    bool m_pressConsumed = false;
    Page *m_pressPage = nullptr;
    bool m_paging = false;
    bool m_longPressFired = false;
    QPointF m_pressPos;
    QPointF m_lastPos;
    double m_dragOffset = 0.0;
    double m_dragVelocity = 0.0;
    qint64 m_lastMoveMs = 0;
};