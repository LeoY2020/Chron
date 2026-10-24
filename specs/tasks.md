# 任务清单（Chron 收尾）

## [x] T1 清理仓库
- 删除 `D:\Users\lenovo\Downloads\Chron\scan.txt`（未跟踪的临时扫描输出）。
- 验证：`git -C D:\Users\lenovo\Downloads\Chron status --short` 不再出现 `?? scan.txt`。

## [x] T2 Linux 静态复核
- 复核 `linux/CMakeLists.txt` 的 `CHRON_SOURCES` / `CHRON_HEADERS` 与 `linux/src` 实际文件一一对应。
- 复核所有 `.cpp` 的 include 与使用一致（`QLinearGradient`/`QPen`/`QDate`/`QByteArray`/`<cmath>`）。
- 复核 `MainWindow` 的按下/移动/释放/长按状态机：页面释放始终转发、长按仅按压未消费时触发、分页阈值 18% 或速度 900px/s。
- 验证：文件数核对 + 括号配平脚本输出为 0 差值。

## [x] T3 HarmonyOS 静态复核
- 复核 `harmonyos` 工程必需文件齐备、`compatibleSdkVersion` 为 `5.0.0(12)`、deviceTypes 含 phone/tablet/2in1。
- 复核 `Index.ets` 三页 Swiper、`disableSwipe(shrink)`、样式栏按页切换样式集与编辑项。
- 验证：`.ets` 括号配平为 0；`main_pages.json` 仅含 `pages/Index`。

## [x] T4 CI 复核
- 复核 `.github/workflows/*.yml` 的工程路径与产物名（`ios/Chron.xcodeproj`、`macos/Chron.xcodeproj`、`android`、`linux`、`windows/Chron.sln`）。
- 复核 artifact glob：`linux/build/chron_*`、`android/app/build/outputs/apk/debug/app-debug.apk`、`Chron-1.0.0-macos.dmg`。
- 验证：文件存在且 YAML 结构完整（可 `python -c "import yaml"` 或人工复核）。

## [x] T5 提交与推送
- `git add` 指定路径：`ios/ macos/ linux/ harmonyos/ .github/ specs/`；提交信息说明 iOS 27 适配、Linux/HarmonyOS 实现与 CI 增补。
- `git push origin main`（使用用户提供的 token；被拦截时先 `AskUserQuestion` 确认）。
- 验证：`git status` 干净、`git log -1` 显示新提交、远程 main 指向该提交。

## [x] T6 CI 结果跟进
- 轮询 GitHub Actions 五个 workflow 的最新运行状态（`gh run list` 或 API）。
- 若失败：仅做最小修复（编译错误、路径、依赖包名），本地静态复核后提交并推送，直至通过或问题超出本机可修复范围。
- 验证：各 workflow 结论为 success，产物 artifact 存在。

## 完成标准
- 工作区无未跟踪残留，远程 `main` 含本次全部改动；
- Linux/Android/Windows/iOS/macOS CI 全绿（HarmonyOS 由本地 DevEco 构建，仅保证工程完整）。