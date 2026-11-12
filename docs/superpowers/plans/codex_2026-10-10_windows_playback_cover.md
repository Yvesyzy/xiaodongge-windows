# Windows 当前播放封面实施计划

**Goal:** 读取 Windows 播放器提供的封面，并在用户保存乐评或速记时安全保存到本地。

**Architecture:** 沿用 Electron preload/IPC → Windows PowerShell 5.1 → WinRT 当前媒体会话，按需从同一媒体属性读取 Thumbnail。前端移植 Android 已验收的自动封面身份绑定和条件存储，保持 Windows 既有功能。

**Tech Stack:** Electron 44.5.1、Node 24.13.0、PowerShell 7.6.5（调度）、Windows PowerShell 5.1（WinRT）、React 19.2.7、TypeScript 6.0.3；Firecrawl CLI 1.19.21 核对官方文档。

**Spec:** `docs/superpowers/specs/codex_2026-10-10_windows_playback_cover.md`

## 执行与证据

工作目录 `D:\codex\workspaces\xiaodongge-windows`；参考只读目录 `D:\codex\workspaces\codex\小懂哥`。输入为项目源文件、Windows 公开媒体会话和合成测试图片；不使用正式个人数据库。输出为本目录源码、`release/codex_windows_cover_*` 验收记录和便携包；网页接口证据在 `.firecrawl/codex_windows_*_20261010.*`。项目当前 clean，原 Android 工作区的未提交改动不得恢复或覆盖。

## Tasks

- [x] 原生：`desktop/native/codex_windows_native.ps1` 新增可选 `IncludeArtwork`，有界读取 Thumbnail、限制尺寸并缩小编码；`desktop/codex_main.cjs` 向原生传递严格布尔选项。最小验证为 PowerShell AST 解析与实际 WinRT 读取，图片失败仍有歌曲元数据。
- [x] 前端：审查参考实现后仅移植 `mobile/src/App.tsx`、`QuickCapturePage.tsx`、`nativeNowPlaying.ts`、`entryDraft.ts`、`store.ts` 所需差异及 `codex_playbackCover.ts`。复用正式封面存储、草稿 schema 和已有读取竞态保护。
- [x] 验证：新增针对自动图像持久化及原生限制的最小检查，使用真实 Electron/SQLite 和独立 profile；检查封面预览/草稿恢复/保存重开、既有手动图、身份变化、坏图、无图。执行 `node --test desktop/codex_now_playing.test.cjs`、`npm.cmd run typecheck`、`npm.cmd run windows:build` 和 `npm.cmd run windows:check`。
- [x] 交付：更新 README/使用说明，构建便携目录与 ZIP 并核对清单和 SHA-256；必要的打包后验证使用隔离 profile。更新项目内会话摘要和 codex_status；累计产物超过 200,000,000 字节按授权清理临时产物，保留最终包与必要证据。

自动执行沿用 Yves 的默认授权；不提交、不推送、不重试已暂停的签名申请，不操作播放器播放/暂停设置。
