# Chron 多平台收尾规格（Linux / HarmonyOS / iOS 27 / CI）

## 背景与当前状态

Chron 仓库：`https://github.com/LeoY2020/Chron`（本地 `D:\Users\lenovo\Downloads\Chron`）。

已完成并已在工作区落盘（未提交）：

- iOS：`IPHONEOS_DEPLOYMENT_TARGET = 27.0`（两个 configuration），按用户要求使用 SDK 27.1 构建、适配 iOS 27；`RootView.swift` 分页/编辑动画改为 `timingCurve(0.4, 0, 0.2, 1)`；`Views/StyleBarView.swift` 外层使用 `.glassEffect(.regular, in: RoundedRectangle(cornerRadius: 24, style: .continuous))`。
- macOS：`MACOSX_DEPLOYMENT_TARGET = 26.0`，同样的动效与 Liquid Glass 调整。
- Linux（新增 `linux/`，Qt6 Widgets + C++17 + CMake 3.16）：
  - `src/Theme.h` 视觉令牌与圆体字体回退、`fitFontSize`、颜色混合；
  - `src/Motion.h` 单值补间（cubic-bezier(0.4,0,0.2,1)）+ `easeOutBack` 回弹；
  - `src/Settings.h/.cpp` 偏好（QSettings）+ 专注记录（JSON，AppDataLocation）；
  - `src/Feedback.h/.cpp` 分级提示音（QSoundEffect 运行时生成 WAV；无 Multimedia 时降级 `QApplication::beep`），并读取“减弱动效”偏好；
  - `src/Page.h` 页面基类（`paint/press/move/release/tick/reset/cancel/isImmersive`）；
  - `src/DurationWheel.h/.cpp` 时/分/秒滚轮（惯性、吸附、边界阻尼、每格轻反馈）；
  - `src/TickScale.h/.cpp` 番茄钟刻度尺（倒三角指针、经过刻度轻反馈、松手惯性吸附）；
  - `src/StyleBar.h/.cpp` 底部样式栏（样式胶囊、就地编辑调色板 5 色、圆环粗细 3 档，`paletteColor`/`thicknessValue` 静态访问）；
  - `src/CountdownPage.h/.cpp` 五种倒计时样式（圆环/扇形/指针/沉浸/全屏沉浸）+ 完成脉冲 + 调时滚轮；
  - `src/PomodoroPage.h/.cpp` 橙色专注氛围、下拉总结（今日/本周 + 近七天柱状趋势）、刻度调时、专注→休息流程与记录写入；
  - `src/ClockPage.h/.cpp` 五种时钟样式（指针/沉浸/全屏沉浸/七段码/太阳，太阳按 8 个时刻关键帧 smoothstep 插值）；
  - `src/MainWindow.h/.cpp` 单画布渲染：三页全屏横向分页（跟手拖拽、边界阻尼、速度/位移判定翻页）、长按 460ms 缩小到 0.93 并唤出样式栏、Esc/方向键/滚轮/F11 桌面交互；释放事件始终转发给页面以兼容“长按优先、点击调时”；
  - `src/main.cpp` Fusion 样式 + 深色 QPalette；
  - `CMakeLists.txt` 3.16、`add_executable(chron WIN32 ...)`、可选 Qt6::Multimedia、`Qt6::EntryPoint`（仅 Windows 且目标存在时）、install（bin/applications/icons）、CPack DEB/RPM/TGZ、DEB 依赖含 `libxcb-cursor0`。
- HarmonyOS（新增 `harmonyos/`，stage model + ArkTS/ArkUI，`compatibleSdkVersion 5.0.0(12)`，deviceTypes phone/tablet/2in1）：
  - 构建骨架：`build-profile.json5`、`hvigorfile.ts`、`oh-package.json5`、`hvigor/hvigor-config.json5`、`AppScope/app.json5` + `resources`、`entry/build-profile.json5`、`entry/hvigorfile.ts`、`entry/oh-package.json5`、`entry/src/main/module.json5`、`main_pages.json`、`element/string.json`、`element/color.json`、`media/app_icon.png`；
  - `theme/ChronTheme.ets` 设计令牌（4px 网格、radius 8/12/16/24、HarmonyOS Sans、纯黑背景）+ 调色板/粗细常量；
  - `model/ChronSettings.ets` preferences 偏好 + JSON 专注记录 + 今日/本周/近七天统计；
  - `services/Feedback.ets`（`@ohos.vibrator` 轻/中/重，尊重“减弱动效”）、`services/TimeFormat.ets`；
  - `entryability/EntryAbility.ets` 初始化偏好、全屏布局、隐藏系统栏；
  - `components/StyleBar.ets`、`DurationWheel.ets`（TextPicker 三列）、`TickScale.ets`（PanGesture 刻度尺）、`CountdownView.ets`（Canvas 扇形/指针 + Progress 圆环 + 长按缩放入口）、`PomodoroView.ets`（下拉总结 + 刻度调时 + 专注流程）、`ClockView.ets`（Canvas 指针/七段码 + 太阳关键帧渐变）；
  - `pages/Index.ets`：Swiper 三页（indicator 关闭、`disableSwipe(shrink)`）、缩放到 0.93 + 圆角 + 黑色底衬、底部样式栏过渡、极简页点。
- CI（新增 `.github/workflows/`）：`ios-build.yml`（`runs-on: xcode-27`，校验 iOS 27 SDK 27.x、Debug 构建 + Release 未签名 archive + 打包未签名 IPA）、`macos-build.yml`（Release 构建 + 未签名 DMG）、`android-build.yml`（JDK 17 + gradle wrapper 8.7 + debug APK）、`linux-build.yml`（qt6-base-dev/qt6-multimedia-dev + CMake/Ninja + CPack DEB/RPM/TGZ）、`windows-build.yml`（.NET 8 + x64 Debug/Release + 产物扁平化）。

## 剩余工作（本规格要决策的范围）

1. 删除仓库根目录未跟踪文件 `scan.txt`。
2. 提交工作区全部改动（iOS/macOS 版本与视觉调整、linux/、harmonyos/、.github/workflows/、specs/），使用中文提交信息，遵循仓库既有风格（英文祈使句 + 简短主题，可附中文说明）。
3. 推送到 `https://github.com/LeoY2020/Chron` 的 `main` 分支（使用用户提供的 token；若 push 被安全策略拦截，先经用户确认）。
4. 推送后轮询 GitHub Actions，记录各平台结果；对可修复的构建错误（Linux C++ 编译、Windows dotnet、Android Gradle、iOS/macOS Xcode）做最小修复并再次提交推送。

## 验证步骤

- 静态自查（本机无 Xcode/Qt/DevEco，不能真编译）：
  - `Get-ChildItem linux/src` 文件齐备（12 个源/头 + CMake）；
  - `CMakeLists.txt` 的 `add_executable` 源列表与实际文件一致；
  - 所有 `.ets` 花括号/圆括号/方括号配平（已核对为 0 差值）；
  - `harmonyos` 工程必需文件齐备（module.json5 / main_pages.json / 资源 / ability / entry 构建文件）。
- CI 验证（推送后）：
  - `ios-build.yml` 通过 “Verify iOS 27 SDK” 步骤（SDK 为 27.x），Debug 构建与未签名 IPA 产出；
  - `macos-build.yml` 产出 DMG；
  - `linux-build.yml` 产出 DEB/RPM/TGZ 与二进制（Qt6 + CHRON_HAS_MULTIMEDIA）；
  - `android-build.yml` 产出 debug APK；
  - `windows-build.yml` 产出 x64 Release 目录；
  - HarmonyOS 无 CI，由本地 DevEco（API 24 / 5.0.0(12)）构建验证，交付前仅保证工程结构完整。

## 约束

- 每次较大改动不得引入新 bug；改动后必须做力所能及的验证（本机仅能做静态与 CI 验证）。
- 不改动既有 iOS/macOS/Android/Windows 的功能语义，仅保留已完成的版本/视觉/动效调整。
- 不新增文档类文件（`specs/` 为本次规格产物，随提交一并纳入或按用户意见排除）。

## 需要用户确认

1. 是否同意按上述范围提交并推送到 `main`（含 `specs/` 目录）。
2. 若 CI 出现失败，是否授权直接做最小修复后继续提交推送。