#include "Feedback.h"

#include <QApplication>
#include <QByteArray>
#include <QDir>
#include <QFile>
#include <QSettings>
#include <QStandardPaths>
#include <QtEndian>
#include <QtMath>
#include <cmath>

#ifdef CHRON_HAS_MULTIMEDIA
#include <QSoundEffect>
#include <QUrl>
#endif

namespace {
constexpr double kPi = 3.14159265358979323846;

bool g_reduceMotion = false;

#ifdef CHRON_HAS_MULTIMEDIA
/// 生成一段带衰减包络的短音，返回本地 wav 路径。
QString toneFile(double frequency, double seconds, double gain) {
    const int sampleRate = 44100;
    const int frames = qMax(1, int(sampleRate * seconds));
    QByteArray pcm(frames * 2, Qt::Uninitialized);
    for (int i = 0; i < frames; ++i) {
        const double t = double(i) / sampleRate;
        const double progress = double(i) / frames;
        const double env = std::exp(-progress * 7.0) * (1.0 - progress * 0.15);
        const double wave = std::sin(2.0 * kPi * frequency * t) * 0.78
                          + std::sin(2.0 * kPi * frequency * 2.0 * t) * 0.22;
        double sample = wave * env * gain;
        sample = qBound(-1.0, sample, 1.0);
        qToLittleEndian<qint16>(qint16(sample * 32767.0), pcm.data() + i * 2);
    }

    QByteArray wav;
    wav.reserve(44 + pcm.size());
    auto append = [&wav](const char *data, int size) { wav.append(data, size); };
    auto append32 = [&wav](quint32 value) {
        char buf[4];
        qToLittleEndian<quint32>(value, buf);
        wav.append(buf, 4);
    };
    auto append16 = [&wav](quint16 value) {
        char buf[2];
        qToLittleEndian<quint16>(value, buf);
        wav.append(buf, 2);
    };
    append("RIFF", 4);
    append32(quint32(36 + pcm.size()));
    append("WAVEfmt ", 8);
    append32(16);
    append16(1);
    append16(1);
    append32(quint32(sampleRate));
    append32(quint32(sampleRate * 2));
    append16(2);
    append16(16);
    append("data", 4);
    append32(quint32(pcm.size()));
    wav.append(pcm);

    const QString dir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QDir().mkpath(dir);
    const QString path = dir + QStringLiteral("/chron-%1.wav").arg(int(frequency));
    QFile file(path);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(wav);
        file.close();
    }
    return path;
}

QSoundEffect *effectFor(Feedback::Level level) {
    static QSoundEffect *light = nullptr;
    static QSoundEffect *medium = nullptr;
    static QSoundEffect *heavy = nullptr;

    QSoundEffect **slot = nullptr;
    double frequency = 0.0;
    double seconds = 0.0;
    double gain = 0.0;
    double volume = 0.0;

    switch (level) {
    case Feedback::Level::Light:
        slot = &light; frequency = 1568.0; seconds = 0.045; gain = 0.10; volume = 0.22;
        break;
    case Feedback::Level::Medium:
        slot = &medium; frequency = 880.0; seconds = 0.085; gain = 0.18; volume = 0.34;
        break;
    case Feedback::Level::Heavy:
        slot = &heavy; frequency = 523.25; seconds = 0.24; gain = 0.24; volume = 0.48;
        break;
    }

    if (!*slot) {
        auto *effect = new QSoundEffect(qApp);
        effect->setSource(QUrl::fromLocalFile(toneFile(frequency, seconds, gain)));
        effect->setVolume(volume);
        *slot = effect;
    }
    return *slot;
}
#endif

} // namespace

namespace Feedback {

void play(Level level) {
    if (g_reduceMotion && level == Level::Light) return;
#ifdef CHRON_HAS_MULTIMEDIA
    QSoundEffect *effect = effectFor(level);
    if (effect) {
        effect->stop();
        effect->play();
    }
#else
    Q_UNUSED(level)
    QApplication::beep();
#endif
}

bool reduceMotion() {
    static bool loaded = false;
    if (!loaded) {
        QSettings settings(QStringLiteral("Chron"), QStringLiteral("Chron"));
        g_reduceMotion = settings.value(QStringLiteral("accessibility/reduceMotion"), false).toBool();
        loaded = true;
    }
    return g_reduceMotion;
}

void setReduceMotion(bool on) {
    g_reduceMotion = on;
}

} // namespace Feedback