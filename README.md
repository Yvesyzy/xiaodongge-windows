# 小懂哥 · Windows 桌面版

把听过的歌、写下的感受和隔一段时间的重听，留在自己的电脑里。

小懂哥是一款以本地档案为主的私人音乐记录应用。Windows 版提供独立桌面窗口、档案双栏阅读、乐评与速记、重听对照和年度回顾。本仓库独立维护 Windows 源码及发行包；[手机端在另一个仓库](https://github.com/Yvesyzy/xiaodongge)。

[下载 Windows 版](https://github.com/Yvesyzy/xiaodongge-windows/releases/latest) · [使用说明](desktop/codex_README.md) · [更新记录](CHANGELOG.md) · [MIT License](LICENSE)

![Windows 首页 · 深色主题](docs/images/codex_windows_home.png)

![Windows 档案双栏 · 浅色主题](docs/images/codex_windows_archive.png)

截图使用合成演示记录。

## 下载与运行

当前版本 **3.1.1**，Windows x64 便携 ZIP，面向 Windows 10 / 11；实际验收系统为 Windows 11 x64。

1. 在 [Releases](https://github.com/Yvesyzy/xiaodongge-windows/releases) 下载 ZIP 和对应的 `.zip.sha256.txt` 校验文件。
2. 将 ZIP **完整解压**到自己的应用目录。
3. 双击 `codex_xiaodongge.exe`。同目录的 DLL、`locales` 和 `resources` 必须保留。

运行发行包不需要安装 Node.js、npm 或数据库。当前发行包未进行代码签名，没有安装向导和自动更新。

在 ZIP 所在目录用 PowerShell 验证下载完整性：

```powershell
Get-ChildItem -Filter '*.zip' | Get-FileHash -Algorithm SHA256
Get-Content -Path '*.zip.sha256.txt'
```

将 ZIP 的 SHA-256 与对应校验文件中的值逐字核对。

## 可以做什么

- **记录音乐**：完整乐评、速记、封面、标签、听歌情境和草稿。
- **六项评分**：制作、词、曲、人声、原创性、共鸣；保留旧总分、加减号和旧版词曲分的原意。
- **整理档案**：搜索、类型与年份筛选、列表和阅读双栏、专辑与歌曲时间轴。
- **重听与回顾**：重听对照、月度和年度回顾、年度专辑榜单及图片导出。
- **桌面原生能力**：文件保存对话框、文件夹选择、剪贴板、当前播放读取和本机截图 OCR。
- **本地备份**：支持 JSON v1–v6，导入前预演差异、恢复失败回滚和撤销上次导入。
- **阅读设置**：深浅主题、字号设置和桌面页面缩放。

## 网易云当前播放

在网易云音乐的 **设置 → 系统** 勾选 **开启SMTC**，保持歌曲播放，再在小懂哥点击「读取当前播放」。暂停时不会作为当前播放读取。

Windows 系统媒体会话未给出专辑或完整合作歌手时，小懂哥会只读本机网易云播放队列，在歌曲名和歌手精确、唯一匹配且没有专辑冲突时补齐。队列缺失、损坏或匹配有歧义时保留系统结果，可以手动校正。读取不会自动保存正式乐评，也不会覆盖已有手填信息。

其他播放器需要提供 Windows 系统媒体会话；本次未逐一验收。OCR 语言取决于系统已安装的语言包，可在「本机诊断」查看。

## 数据、备份与更新

正式档案位于：

```text
%APPDATA%\xiaodongge-windows\archive\music_feelings_archive.sqlite
```

草稿、主题和阅读偏好位于同一应用数据目录中的 Chromium 存储。便携程序所在目录与个人数据目录分开，移动程序目录不会随之移动档案。

从安卓版迁移时，先在手机导出包含封面的 JSON，在 Windows 的「备份与恢复」中选择文件并预演差异，核对后再导入。**导入会整体替换本机档案**，请保留原备份；JSON v1–v5 缺少草稿时保留本机草稿，v6 按备份替换草稿。两端通过手动 JSON 备份迁移，没有云同步。

更新时先导出 JSON 并正常关闭旧版，再把新版解压到新目录运行。程序沿用固定的应用数据目录；复制程序目录不能替代备份。

本地记录可以离线使用。当前播放的目录补全会使用 Apple iTunes；仅在手动选择城市后请求 Open-Meteo 天气。本机网易云队列补全与截图 OCR 不需要联网。

## 从源码构建

使用 **Windows x64、Node.js 24 或以上版本、npm、PowerShell 7**。原生媒体会话和 OCR 辅助程序使用系统自带的 Windows PowerShell 5.1。

```powershell
git clone https://github.com/Yvesyzy/xiaodongge-windows.git
cd xiaodongge-windows
npm.cmd ci
node node_modules/electron/install.js
npm.cmd run typecheck
npm.cmd test
npm.cmd run windows:build
npm.cmd run windows:start
```

生成便携 ZIP：

```powershell
npm.cmd run windows:package
```

产物写入被 Git 忽略的 `release/`：完整运行目录、ZIP、SHA-256 文件及 `codex_windows_latest.json`。打包脚本直接从源码构建页面，逐项核对 ZIP 中每个交付文件的大小和 SHA-256。

Electron 运行时通过上面的安装命令单独下载；保留 Electron 包附带的校验和。

## 验证

```powershell
npm.cmd run windows:check
```

该脚本在 `release/` 内创建独立 profile 和合成记录，不读取正式个人档案。覆盖 SQLite、草稿、备份预演/恢复/回滚/撤销、原生导出、OCR 和深浅主题布局。将 `release/codex_windows_latest.json` 中 `executable` 的实际路径作为参数传给 `windows:check`，还会检查便携目录搬移及离线冷启动、保存与导出。

`npm.cmd test` 包含共享备份/分析规则、Windows SQLite 和网易云队列补全的单元测试。真实网易云播放检查使用 `node scripts/codex_check_windows_playback.mjs`；运行前保持网易云播放，该检查会暂停并恢复播放。

本次发行的验证范围见 [Release 说明](docs/codex_release_v3.1.1.md)。Windows 10 和个人 Android 备份的跨端迁移仍需实际设备验收。

## 源码结构

```text
desktop/       Electron 主进程、受限桥接、SQLite、WinRT 辅助程序及桌面界面
mobile/src/    Windows 复用的记录、回顾、备份与阅读组件
mobile/public/ 字体授权说明
shared/        备份、听歌情境与分析规则及单元测试
scripts/       Windows 构建、验收与媒体会话检查
docs/          发行说明与界面截图
```

`mobile/` 保留原有相对导入路径，仓库无需手机端源码目录、Android SDK 或手机端仓库才能构建。Windows 与手机端今后各自提交、发布。

## 授权

项目源码采用 [MIT License](LICENSE)。Electron、Chromium 及所用字体的第三方授权说明随发行包保留。
