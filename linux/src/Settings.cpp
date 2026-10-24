#include "Settings.h"

#include <QDate>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSettings>
#include <QStandardPaths>

namespace {
QSettings store() {
    return QSettings(QStringLiteral("Chron"), QStringLiteral("Chron"));
}
const char *kCountdownStyle = "countdown/style";
const char *kClockStyle = "clock/style";
const char *kCountdownSeconds = "countdown/seconds";
const char *kCountdownColor = "countdown/color";
const char *kClockColor = "clock/color";
const char *kBackgroundAlpha = "style/backgroundAlpha";
const char *kRingThickness = "countdown/ringThickness";
const char *kFocusSeconds = "pomodoro/focusSeconds";
const char *kBreakSeconds = "pomodoro/breakSeconds";
}

Settings &Settings::instance() {
    static Settings instance;
    return instance;
}

Settings::Settings(QObject *parent) : QObject(parent) {
    QSettings settings = store();
    m_countdownStyle = qBound(0, settings.value(kCountdownStyle, 0).toInt(), 4);
    m_clockStyle = qBound(0, settings.value(kClockStyle, 1).toInt(), 4);
    m_countdownSeconds = qBound(1, settings.value(kCountdownSeconds, 300).toInt(), 24 * 3600);
    m_countdownColor = settings.value(kCountdownColor, QStringLiteral("F5F5F7")).toString();
    m_clockColor = settings.value(kClockColor, QStringLiteral("F5F5F7")).toString();
    m_backgroundAlpha = qBound(0, settings.value(kBackgroundAlpha, 0).toInt(), 60);
    m_ringThickness = qBound(2, settings.value(kRingThickness, 10).toInt(), 28);
    m_focusSeconds = qBound(60, settings.value(kFocusSeconds, 25 * 60).toInt(), 90 * 60);
    m_breakSeconds = qBound(30, settings.value(kBreakSeconds, 5 * 60).toInt(), 30 * 60);
    loadHistory();
}

void Settings::persist() {
    QSettings settings = store();
    settings.setValue(kCountdownStyle, int(m_countdownStyle));
    settings.setValue(kClockStyle, int(m_clockStyle));
    settings.setValue(kCountdownSeconds, m_countdownSeconds);
    settings.setValue(kCountdownColor, m_countdownColor);
    settings.setValue(kClockColor, m_clockColor);
    settings.setValue(kBackgroundAlpha, m_backgroundAlpha);
    settings.setValue(kRingThickness, m_ringThickness);
    settings.setValue(kFocusSeconds, m_focusSeconds);
    settings.setValue(kBreakSeconds, m_breakSeconds);
    emit changed();
}

QString Settings::historyFilePath() const {
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dir);
    return dir + QStringLiteral("/history.json");
}

void Settings::loadHistory() {
    QFile file(historyFilePath());
    if (!file.open(QIODevice::ReadOnly)) return;
    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    if (!doc.isArray()) return;
    const QJsonArray array = doc.array();
    m_history.reserve(array.size());
    for (const QJsonValue &value : array) {
        const QJsonObject object = value.toObject();
        FocusRecord record;
        record.start = QDateTime::fromString(object.value(QStringLiteral("start")).toString(), Qt::ISODate);
        record.seconds = object.value(QStringLiteral("seconds")).toInt();
        if (record.start.isValid() && record.seconds > 0) m_history.append(record);
    }
}

void Settings::saveHistory() const {
    QJsonArray array;
    for (const FocusRecord &record : m_history) {
        QJsonObject object;
        object.insert(QStringLiteral("start"), record.start.toString(Qt::ISODate));
        object.insert(QStringLiteral("seconds"), record.seconds);
        array.append(object);
    }
    QFile file(historyFilePath());
    if (file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        file.write(QJsonDocument(array).toJson(QJsonDocument::Compact));
        file.close();
    }
}

Settings::CountdownStyle Settings::countdownStyle() const {
    return CountdownStyle(int(m_countdownStyle));
}

void Settings::setCountdownStyle(CountdownStyle style) {
    if (int(m_countdownStyle) == int(style)) return;
    m_countdownStyle = int(style);
    persist();
}

Settings::ClockStyle Settings::clockStyle() const {
    return ClockStyle(int(m_clockStyle));
}

void Settings::setClockStyle(ClockStyle style) {
    if (int(m_clockStyle) == int(style)) return;
    m_clockStyle = int(style);
    persist();
}

int Settings::countdownSeconds() const { return m_countdownSeconds; }

void Settings::setCountdownSeconds(int seconds) {
    seconds = qBound(1, seconds, 24 * 3600);
    if (seconds == m_countdownSeconds) return;
    m_countdownSeconds = seconds;
    persist();
}

QString Settings::countdownColorHex() const { return m_countdownColor; }

void Settings::setCountdownColorHex(const QString &hex) {
    if (hex == m_countdownColor) return;
    m_countdownColor = hex;
    persist();
}

QString Settings::clockColorHex() const { return m_clockColor; }

void Settings::setClockColorHex(const QString &hex) {
    if (hex == m_clockColor) return;
    m_clockColor = hex;
    persist();
}

int Settings::backgroundAlpha() const { return m_backgroundAlpha; }

void Settings::setBackgroundAlpha(int alpha) {
    alpha = qBound(0, alpha, 60);
    if (alpha == m_backgroundAlpha) return;
    m_backgroundAlpha = alpha;
    persist();
}

int Settings::ringThickness() const { return m_ringThickness; }

void Settings::setRingThickness(int thickness) {
    thickness = qBound(2, thickness, 28);
    if (thickness == m_ringThickness) return;
    m_ringThickness = thickness;
    persist();
}

int Settings::focusSeconds() const { return m_focusSeconds; }

void Settings::setFocusSeconds(int seconds) {
    seconds = qBound(60, seconds, 90 * 60);
    if (seconds == m_focusSeconds) return;
    m_focusSeconds = seconds;
    persist();
}

int Settings::breakSeconds() const { return m_breakSeconds; }

void Settings::setBreakSeconds(int seconds) {
    seconds = qBound(30, seconds, 30 * 60);
    if (seconds == m_breakSeconds) return;
    m_breakSeconds = seconds;
    persist();
}

const QVector<FocusRecord> &Settings::history() const { return m_history; }

void Settings::addFocus(int seconds) {
    if (seconds <= 0) return;
    FocusRecord record;
    record.start = QDateTime::currentDateTime();
    record.seconds = seconds;
    m_history.append(record);
    saveHistory();
    emit changed();
}

int Settings::todayCount() const {
    const QDate today = QDate::currentDate();
    int count = 0;
    for (const FocusRecord &record : m_history) {
        if (record.start.date() == today) ++count;
    }
    return count;
}

int Settings::todaySeconds() const {
    const QDate today = QDate::currentDate();
    int total = 0;
    for (const FocusRecord &record : m_history) {
        if (record.start.date() == today) total += record.seconds;
    }
    return total;
}

int Settings::weekCount() const {
    const QDate monday = QDate::currentDate().addDays(1 - QDate::currentDate().dayOfWeek());
    int count = 0;
    for (const FocusRecord &record : m_history) {
        if (record.start.date() >= monday) ++count;
    }
    return count;
}

int Settings::weekSeconds() const {
    const QDate monday = QDate::currentDate().addDays(1 - QDate::currentDate().dayOfWeek());
    int total = 0;
    for (const FocusRecord &record : m_history) {
        if (record.start.date() >= monday) total += record.seconds;
    }
    return total;
}

QVector<int> Settings::last7DaysMinutes() const {
    QVector<int> minutes(7, 0);
    const QDate today = QDate::currentDate();
    for (const FocusRecord &record : m_history) {
        const QDate date = record.start.date();
        const int index = int(date.daysTo(today));
        if (index >= 0 && index < 7) minutes[6 - index] += record.seconds / 60;
    }
    return minutes;
}