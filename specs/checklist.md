# 检查清单（Chron 收尾）

- [x] iOS 工程部署目标为 27.0，CI 使用 SDK 27.1 并校验 `iphoneos27.*` 后构建成功
- [x] macOS 工程部署目标为 26.0，CI 产出未签名 DMG
- [x] iOS/macOS 动效统一为 cubic-bezier(0.4, 0, 0.2, 1)，样式栏使用 Liquid Glass
- [x] Linux 工程可由 CMake 构建，CI 产出 DEB/RPM/TGZ 与可执行文件
- [x] HarmonyOS 工程文件齐备（SDK 5.0.0(12)、phone/tablet/2in1、Swiper 三页与样式栏）
- [x] 五个 GitHub Actions workflow 在 main 最新提交上全部通过
- [x] `specs/` 文档与仓库改动全部提交并推送，工作区无未跟踪残留