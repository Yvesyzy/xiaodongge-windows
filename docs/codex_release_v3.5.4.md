# 小懂哥 Windows 桌面版 v3.5.4

发布日期：2026-11-13。版本 `3.5.4`，与手机端 v3.5.4 对应。本次为**公众号出稿**的连续两轮调整：评分段落结构固定、去掉配图管线、单篇稿件不再重复标题。功能面与手机端一致，Windows 端版本号从 3.5.2 直接跟到 3.5.4。

## 本次改动

### 六项评分固定输出

评分段落不再取决于这条记录填了几项。制作、词、曲、人声、原创性、共鸣六项始终输出，未填写的维度写「未填写」，稳定排成两行三项，与三项日期的处理方式一致。此前记录缺项时整行会消失，导致不同记录的稿件结构不一致。

导出后的评分段落形如：

```markdown
评分：8.5+ / 10

制作：9/10 · 词：8/10 · 曲：8.5/10

人声：9/10 · 原创性：8/10 · 共鸣：7.5/10
```

### 删除旧版词曲评分

`ratingSongwriting` 是早期版本的兼容字段，之前被当成第七个维度导出，把六项挤成「3 + 3 + 1」，共鸣单独占一行。现在它不进入稿件；本机已有的旧记录数据与编辑表单不受影响。

### 删除配图管线

出稿页不再有「附上这一节的封面配图」勾选，Markdown 不再生成 `> 【配图位置】…` 提醒块，纯文本与 HTML 输出也不再带配图占位；随之一并移除封面读取、PNG 转码与横版封面预览。公众号编辑器里那个删不掉的提示框不会再出现。

旧草稿里的 `coverDataUrl` 与 `includeImage` 仍会被解析器接受，避免升级后草稿校验失败，但读取时丢弃，不参与任何输出。

### 旧草稿元信息重建

恢复本机推文草稿时，专辑／歌曲／艺术家、评分、日期按当前记录重新生成，只保留用户编辑过的章节标题与正文。旧版本保存的草稿缺少结构化元信息时，不会再退回「音乐 / 评分 / 日期」三行旧格式。

### 单篇稿件不再出现两遍标题

单篇乐评的章节标题默认与推文标题相同，此前导出会同时生成 `# 推文标题` 和 `## 同名章节标题`，导入公众号后顶部标题下面又出现一次同名小标题。现在两处名称相同时省略章节标题，只保留顶部 H1；改了章节标题、或一篇里排了多节时，章节标题照常保留。规则同时作用于 Markdown、纯文本与页面内预览。

## 下载与校验

- [便携 ZIP](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.4/codex_xiaodongge_windows_3.5.4_x64_20261113_022525.zip) — 165,389,420 字节
- [便携 ZIP SHA-256](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.4/codex_xiaodongge_windows_3.5.4_x64_20261113_022525.zip.sha256.txt)

```
dbf2c66749b48c8d7c3d638df141239d584f09ffdb71e70cc3067833ab2051d4  codex_xiaodongge_windows_3.5.4_x64_20261113_022525.zip
```

- [每用户安装器（自签名）](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.4/codex_xiaodongge_windows_3.5.4_x64_setup_signed_20261113_023439_318.exe) — 122,585,632 字节
- [安装器 SHA-256](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.4/codex_xiaodongge_windows_3.5.4_x64_setup_signed_20261113_023439_318.exe.sha256.txt)

```
3a3251129bd3b4baec2e54fad919092b9be97355ddf9feefc84638172fd820766  codex_xiaodongge_windows_3.5.4_x64_setup_signed_20261113_023439_318.exe
```

## 覆盖升级与数据

数据库结构未改动，JSON v6 备份格式不变。实测从 3.5.2 静默覆盖安装到 3.5.4：注册表 `DisplayVersion` 变为 `3.5.4`，安装目录与清单逐文件比对 `missing 0`，上一版残留的哈希文件名资源由安装器的 `[InstallDelete]` 清除；用户数据目录 `%APPDATA%\xiaodongge-windows` 未受影响，安装后 SQLite 与 Chromium 写入均可回读。

已保存的推文草稿会保留，但配图勾选与配图字段在读取时被丢弃——这是本次的预期行为。仍建议升级前导出完整 JSON 备份。

## 验证范围

- `tsc --noEmit` 通过；Node 24 单测 **71/71**（含单篇标题去重与旧草稿配图字段丢弃用例）；Vite 生产构建通过。
- 便携包 104 个文件逐项大小与 SHA-256 校验通过；安装器构建核对同一清单。
- 真实 Electron 回归 **19 组 + 12 组深浅主题布局，0 页面错误**，新增「出稿固定输出六项评分、无配图管线、标题不重复」场景；写作页扩展区标题断言为非 `sticky`（沿用 11-13 补丁）。
- 已安装程序实测：`INSTALLED_APP_WRITE_PASS` / `READ_PASS`；出稿页单篇导出 `sectionHeadings` 为空、预览无同名标题、无「配图位置」与「旧版词曲」，评分两行三项（缺项显示「未填写」）。
- 安装器与内嵌主程序带 RFC 3161 时间戳，本机 `Get-AuthenticodeSignature` 为 `Valid`。

## 已知限制

- 安装器使用本机创建的**自签名开发证书**，不是受信任 CA 签发的发布者证书；仅在已导入其根证书的本机验证为有效，其他 Windows 机器会显示签名无效或未知发布者，SmartScreen 提示不会消失。便携 ZIP 未签名。SignPath Foundation 申请仍在等待回复。
- 配图能力已按手机端决策整体移除；如后续要恢复，需要重新引入封面读取、PNG 转码与横版封面渲染三条链路。
- 推文草稿不在 JSON 备份内，仍需在出稿页单独导出 Markdown 稿。
- 只在 Windows 11 x64 实测；Windows 10 与真机 Android 跨端导入仍待实机验收。

历史版本：[v3.5.2](https://github.com/Yvesyzy/xiaodongge-windows/releases/tag/v3.5.2)、[v3.5.1](https://github.com/Yvesyzy/xiaodongge-windows/releases/tag/v3.5.1)。
