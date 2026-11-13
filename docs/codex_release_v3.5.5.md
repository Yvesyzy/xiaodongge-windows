# 小懂哥 Windows 桌面版 v3.5.5

发布日期：2026-11-13。版本 `3.5.5`，与手机端 v3.5.5 对应。本次只调整**公众号出稿**的元信息排列，不涉及数据库、备份格式与既有记录。

## 本次改动

### 元信息改为三段式排版

原来专辑、歌曲、艺术家、评分、六项维度与三个日期是一条平铺的列表，行距完全一致，打开稿件时分不清哪几行讲基本信息、哪几行讲评分。现在分成三块，块与块之间留两个空行：

1. **基本信息**：专辑 → 艺术家 → 歌曲
2. **评分**：总分 + 两行维度（每行三项）
3. **日期**：发行时间 → 首次收听 → 乐评记录

块内每行之间仍是一个空行。字段顺序同时调整为「专辑 → 艺术家 → 歌曲」，此前「歌曲」排在「艺术家」之前。

导出后的结构形如：

```markdown
# 南下南下

专辑：南下南下

艺术家：OuttaWave

歌曲：东北DNB/老马/一砖一瓦/Country Road


评分：7.1 / 10

制作：7.5/10 · 词：7.5/10 · 曲：7/10

人声：6/10 · 原创性：7/10 · 共鸣：7.5/10


专辑/歌曲发行时间：2026.03.28

首次收听时间：2026.03.31

乐评记录时间：2026.11.10
```

Markdown、纯文本与页面内预览三处输出保持一致；HTML 片段按组包裹，粘贴到公众号编辑器后同样是「组内一行、组间一段」的观感。空行是真实空行，不依赖公众号导入器不支持的行尾双空格。

## 下载与校验

- [便携 ZIP](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.5/codex_xiaodongge_windows_3.5.5_x64_20261113_040718.zip) — 165,389,480 字节
- [便携 ZIP SHA-256](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.5/codex_xiaodongge_windows_3.5.5_x64_20261113_040718.zip.sha256.txt)

```
7f553a69361dd7994264f7430dcede02f42738788312546d9206ce5cab0c552e  codex_xiaodongge_windows_3.5.5_x64_20261113_040718.zip
```

- [每用户安装器（自签名）](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.5/codex_xiaodongge_windows_3.5.5_x64_setup_signed_20261113_041023_334.exe) — 122,594,432 字节
- [安装器 SHA-256](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.5/codex_xiaodongge_windows_3.5.5_x64_setup_signed_20261113_041023_334.exe.sha256.txt)

```
edb0a362f2589e60a44d6f2567c50515dbb6502bbdf11e50c7ae7c53514e4873  codex_xiaodongge_windows_3.5.5_x64_setup_signed_20261113_041023_334.exe
```

## 覆盖升级与数据

数据库结构未改动，JSON v6 备份格式不变。记录存放在 `%APPDATA%\xiaodongge-windows\archive`，与安装目录分离，覆盖升级只替换程序文件。本版沿用 3.5.2 起生效的 `[InstallDelete]`，升级前清掉旧版带哈希名的 js/css，不残留上一版资源。

## 验证范围

- `tsc --noEmit` 通过；Node 24 单测全过（含新的三段式断言）；Vite 生产构建通过。
- 便携包逐文件大小与 SHA-256 校验通过；安装器构建核对同一清单。
- 真实 Electron 回归：窗口/主题布局与已安装程序持久化检查全过。
- 安装器与内嵌主程序带 RFC 3161 时间戳，本机 `Get-AuthenticodeSignature` 为 `Valid`。

## 已知限制

- 安装器使用本机创建的**自签名开发证书**，不是受信任 CA 签发的发布者证书；仅在已导入其根证书的本机验证为有效，其他 Windows 机器会显示签名无效或未知发布者。便携 ZIP 未签名。SignPath Foundation 申请仍在等待回复。
- 推文草稿不在 JSON 备份内，仍需在出稿页单独导出 Markdown 稿。
- 只在 Windows 11 x64 实测；Windows 10 与真机 Android 跨端导入仍待实机验收。

历史版本：[v3.5.4](https://github.com/Yvesyzy/xiaodongge-windows/releases/tag/v3.5.4)、[v3.5.2](https://github.com/Yvesyzy/xiaodongge-windows/releases/tag/v3.5.2)、[v3.5.1](https://github.com/Yvesyzy/xiaodongge-windows/releases/tag/v3.5.1)。
