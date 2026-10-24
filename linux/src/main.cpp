#include <QApplication>
#include <QPalette>
#include <QStyleFactory>

#include "Feedback.h"
#include "MainWindow.h"
#include "Theme.h"

int main(int argc, char *argv[]) {
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("Chron"));
    QApplication::setOrganizationName(QStringLiteral("Chron"));
    QApplication::setApplicationDisplayName(QStringLiteral("Chron"));
    QApplication::setApplicationVersion(QStringLiteral("1.0.0"));

    if (QStyle *fusion = QStyleFactory::create(QStringLiteral("Fusion"))) {
        app.setStyle(fusion);
    }

    QPalette palette;
    palette.setColor(QPalette::Window, Theme::bg());
    palette.setColor(QPalette::WindowText, Theme::ink());
    palette.setColor(QPalette::Base, Theme::bg());
    palette.setColor(QPalette::Text, Theme::ink());
    palette.setColor(QPalette::ButtonText, Theme::ink());
    palette.setColor(QPalette::Highlight, Theme::warm());
    palette.setColor(QPalette::HighlightedText, QColor(12, 12, 14));
    app.setPalette(palette);

    Feedback::reduceMotion();

    MainWindow window;
    window.show();
    return app.exec();
}