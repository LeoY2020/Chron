cmake_minimum_required(VERSION 3.16)
project(Chron VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt6 6.4 REQUIRED COMPONENTS Widgets)
find_package(Qt6 QUIET COMPONENTS Multimedia)

set(CHRON_SOURCES
    src/main.cpp
    src/MainWindow.cpp
    src/Settings.cpp
    src/Feedback.cpp
    src/StyleBar.cpp
    src/DurationWheel.cpp
    src/TickScale.cpp
    src/CountdownPage.cpp
    src/PomodoroPage.cpp
    src/ClockPage.cpp
)

set(CHRON_HEADERS
    src/MainWindow.h
    src/Settings.h
    src/Feedback.h
    src/StyleBar.h
    src/DurationWheel.h
    src/TickScale.h
    src/CountdownPage.h
    src/PomodoroPage.h
    src/ClockPage.h
    src/Page.h
    src/Theme.h
    src/Motion.h
)

add_executable(chron WIN32 ${CHRON_SOURCES} ${CHRON_HEADERS})

target_link_libraries(chron PRIVATE Qt6::Widgets)

if (WIN32 AND TARGET Qt6::EntryPoint)
    target_link_libraries(chron PRIVATE Qt6::EntryPoint)
endif()

if (Qt6Multimedia_FOUND)
    target_link_libraries(chron PRIVATE Qt6::Multimedia)
    target_compile_definitions(chron PRIVATE CHRON_HAS_MULTIMEDIA=1)
endif()

if (MSVC)
    target_compile_options(chron PRIVATE /W3)
else()
    target_compile_options(chron PRIVATE -Wall -Wextra)
endif()

include(GNUInstallDirs)
install(TARGETS chron RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES packaging/chron.desktop DESTINATION ${CMAKE_INSTALL_DATADIR}/applications)
install(FILES packaging/chron.svg DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps)

set(CPACK_PACKAGE_NAME "chron")
set(CPACK_PACKAGE_VENDOR "Chron")
set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "A quiet, distraction-free clock")
set(CPACK_PACKAGE_VERSION ${PROJECT_VERSION})
set(CPACK_PACKAGE_CONTACT "Chron <chron@localhost>")
set(CPACK_DEBIAN_PACKAGE_MAINTAINER "Chron <chron@localhost>")
set(CPACK_DEBIAN_PACKAGE_DEPENDS "libc6, libstdc++6, libqt6core6 (>= 6.4), libqt6gui6 (>= 6.4), libqt6widgets6 (>= 6.4), libxcb-cursor0")
set(CPACK_RPM_PACKAGE_LICENSE "MIT")
set(CPACK_RPM_PACKAGE_REQUIRES "qt6-qtbase >= 6.4")
set(CPACK_GENERATOR "DEB;RPM;TGZ")
set(CPACK_PACKAGE_FILE_NAME "${CPACK_PACKAGE_NAME}_${PROJECT_VERSION}_${CMAKE_SYSTEM_PROCESSOR}")
include(CPack)