# 小懂哥 Windows v3.1.1

Windows 独立仓库首个发行版本。沿用现有程序版本号 3.1.1，手机端由 [Yvesyzy/xiaodongge](https://github.com/Yvesyzy/xiaodongge) 单独维护。

## 下载与启动

下载本 Release 附带的 Windows x64 ZIP 和同名 `.zip.sha256.txt`。完整解压后双击 `codex_xiaodongge.exe`，保留同目录的 DLL、`locales` 和 `resources`。无需安装 Node.js、npm 或数据库。

面向 Windows 10 / 11 x64，实际验收为 Windows 11 x64。当前为未签名便携版，没有安装向导和自动更新。

## 本次内容

- 独立桌面窗口、固定侧栏、首页和档案双栏阅读，支持搜索、类型与年份筛选。
- 乐评、速记、草稿、六项评分、重听对照、月度/年度回顾与图片导出。
- 本地 SQLite，JSON v1–v6 备份，导入前隔离预演、失败回滚和撤销。
- 原生文件与文件夹对话框、剪贴板、Windows 当前播放和本机截图 OCR。
- 网易云专辑和完整合作歌手补全：只读本机播放队列，精确唯一匹配后补齐；暂停、歧义和专辑冲突时保留系统结果。

## 使用与迁移

网易云请先在「设置 → 系统」开启「开启SMTC」并保持播放。其他播放器需提供 Windows 系统媒体会话，OCR 语言取决于系统组件。

从安卓版导出包含封面的 JSON，在 Windows「备份与恢复」预演并核对后导入。导入整体替换本机档案，务必保留原备份。两端通过 JSON 手动迁移，没有云同步。

个人档案位于 `%APPDATA%\xiaodongge-windows\archive\music_feelings_archive.sqlite`。更新时先导出备份、关闭旧版，再将新版解压到新目录运行；沿用固定应用数据目录。

详细操作见 [Windows 使用说明](https://github.com/Yvesyzy/xiaodongge-windows/blob/main/desktop/codex_README.md)。Windows 10、其他播放器和个人 Android 备份迁移不在本次实际验收范围内。

## 验证结果

本发行包由独立 Windows 仓库源码重新构建，应用业务源文件与原工作区逐一核对一致。

- 独立依赖安装与 TypeScript 类型检查通过，48 项单元测试全部通过。
- 18 组真实 Electron / Windows 桌面验收通过，包括草稿持久化、v1–v6 备份往返、隔离预演、失败回滚、撤销、原生导出、剪贴板和本机 OCR。
- 两种窗口尺寸 × 三档缩放 × 深浅主题，共 12 组布局检查通过。
- 移动完整便携目录后，屏蔽 HTTP/HTTPS 冷启动、档案与草稿保留、离线保存与导出通过。
- ZIP 内 98 项交付文件的大小与 SHA-256 逐项通过；主进程、preload、SQLite、网易云补全和原生辅助脚本与源码一致。
- npm 生产依赖审计：0 项已知漏洞（2026-10-07）。

运行时为 Electron 44.5.1、Node 24.21.0、SQLite 3.53.4。详细记录见 [发行验收 JSON](https://github.com/Yvesyzy/xiaodongge-windows/blob/main/docs/codex_release_verification_v3.1.1.json)。

## 发行文件

- 文件：`codex_xiaodongge_windows_3.1.1_x64_20261007_032400.zip`
- 大小：170,688,569 字节（约 162.78 MiB）
- SHA-256：

```text
8c45c18a6d18d62b4d0d22733ff04fc6eb65797921a45c3ee84db7f012ea35ff
```

文件名时间戳采用 UTC；本次发行日期为北京时间 2026-10-07。
