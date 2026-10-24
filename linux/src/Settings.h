#pragma once

#include <QDateTime>
#include <QObject>
#include <QString>
#include <QVector>

struct FocusRecord {
    QDateTime start;
    int seconds = 0;
};

/// 全部偏好与专注记录的唯一来源。偏好走 QSettings，记录走 JSON 文件。
class Settings : public QObject {
    Q_OBJECT

public:
    enum class CountdownStyle { Ring, Sector, Dial, Plain, Immersive };
    enum class ClockStyle { Analog, Plain, Immersive, SevenSegment, Sun };

    static Settings &instance();

    CountdownStyle countdownStyle() const;
    void setCountdownStyle(CountdownStyle style);

    ClockStyle clockStyle() const;
    void setClockStyle(ClockStyle style);

    int countdownSeconds() const;
    void setCountdownSeconds(int seconds);

    QString countdownColorHex() const;
    void setCountdownColorHex(const QString &hex);

    QString clockColorHex() const;
    void setClockColorHex(const QString &hex);

    /// 背景微色调透明度（0–60，0 为纯黑）。
    int backgroundAlpha() const;
    void setBackgroundAlpha(int alpha);

    /// 圆环 / 表盘线宽（像素）。
    int ringThickness() const;
    void setRingThickness(int thickness);

    int focusSeconds() const;
    void setFocusSeconds(int seconds);

    int breakSeconds() const;
    void setBreakSeconds(int seconds);

    /// 专注记录。
    const QVector<FocusRecord> &history() const;
    void addFocus(int seconds);
    int todayCount() const;
    int todaySeconds() const;
    int weekCount() const;
    int weekSeconds() const;
    /// 最近七天每天的专注分钟数（含今天，索引 6 为今天）。
    QVector<int> last7DaysMinutes() const;

signals:
    void changed();

private:
    explicit Settings(QObject *parent = nullptr);

    void persist();
    void loadHistory();
    void saveHistory() const;
    QString historyFilePath() const;

    int m_countdownStyle = 0;
    int m_clockStyle = 1;
    int m_countdownSeconds = 300;
    QString m_countdownColor = QStringLiteral("F5F5F7");
    QString m_clockColor = QStringLiteral("F5F5F7");
    int m_backgroundAlpha = 0;
    int m_ringThickness = 10;
    int m_focusSeconds = 25 * 60;
    int m_breakSeconds = 5 * 60;
    QVector<FocusRecord> m_history;
};