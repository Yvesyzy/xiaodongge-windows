# 小懂哥 Windows 桌面版 v3.5.1

发布日期：2026-11-12。版本 `3.5.1`，与手机端 v3.5.1 功能对齐，并纳入此前未正式发布的 3.2.0 / 3.2.1 系统播放封面改动。Windows 10 / 11 x64；实际验收系统为 Windows 11 x64。

## 本次改动

- **公众号 Markdown 出稿**：新增出稿页（侧栏「出稿与报告」），提供「导出 Markdown 稿」「分享 MD 文件」「复制 Markdown 全文」与页内全文预览。导出文件名按专辑名优先、歌曲名次之，回退章节标题或推文标题；清洗 `\ / : * ? " < > |` 与控制字符，按码点截断 60 字符。
- **稿件排版**：元信息逐项独立成段，不使用行尾双空格硬换行；六个评分维度每三项合成一行、行内用「 · 」分隔；三项日期（专辑/歌曲发行时间、首次收听时间、乐评记录时间）全部统计，格式 `YYYY.MM.DD`，缺失显示「未填写」。隐藏评分／隐藏日期开关对 Markdown、纯文字与预览同时生效。
- **日期录入**：发行时间、首次收听时间以及重听／速记的收听日期改为年／月／日三列滚轮，弹层内输入四位年份可一步跳转；保留同名文本输入作为数据载体，草稿恢复与既有检查不变。
- **日期口径**：归档与月报／年报支持按发行时间、乐评记录时间、首次收听时间切换；桌面双栏「全部记录」页新增「归档口径」下拉，排序与年份筛选随口径变化。
- **年度报告**：新增 `/annual-report`，只统计当年发行的新专辑，含年度前十五专辑与新老专辑统计，榜单与年度总结分开保存。
- **Windows 原生适配**：导出扩展名白名单新增 `.md`；「分享 MD 文件」写入导出文件夹并打开资源管理器，「复制 Markdown 全文」写入系统剪贴板；本地图片保存复用文件对话框。
- **系统播放封面**：3.2.0 按需读取 Windows SMTC Thumbnail 并随乐评／速记保存；3.2.1 取消缩放与 JPEG 重编码，保留播放器原始字节、格式与尺寸，安全上限 4 MiB / 20 MP。

不含手机端专属的好友圈、隐私同意门禁与 Android 兼容性页；这些能力依赖 Android 原生插件或外部服务。

## 下载与校验

- [便携 ZIP](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.1/codex_xiaodongge_windows_3.5.1_x64_20261112_011828.zip) — `codex_xiaodongge_windows_3.5.1_x64_20261112_011828.zip`，170,722,333 字节
- [便携 ZIP SHA-256](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.1/codex_xiaodongge_windows_3.5.1_x64_20261112_011828.zip.sha256.txt)

```
da80511ccea5b15c33363aa3ec930be073f964fece727c5887ab6ba77e8484a4  codex_xiaodongge_windows_3.5.1_x64_20261112_011828.zip
```

- [每用户安装器（未签名）](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.1/codex_xiaodongge_windows_3.5.1_x64_setup_unsigned_20261112_012301_795.exe) — 122,536,618 字节
- [安装器 SHA-256](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.1/codex_xiaodongge_windows_3.5.1_x64_setup_unsigned_20261112_012301_795.exe.sha256.txt)

```
7d01bed65e01ca25c6e72cd1da92847c2c8b0091808c228fe1088e161a26dd38  codex_xiaodongge_windows_3.5.1_x64_setup_unsigned_20261112_012301_795.exe
```

在下载目录用 PowerShell 核对：

```powershell
Get-ChildItem -Filter '*.zip' | Get-FileHash -Algorithm SHA256
Get-Content -Path '*.zip.sha256.txt'
```

安装器默认装到 `%LOCALAPPDATA%\Programs\xiaodongge-windows`，提供开始菜单入口与可选桌面快捷方式，无需管理员权限。便携版需**完整解压**后运行 `codex_xiaodongge.exe`，同目录 DLL、`locales` 与 `resources` 必须保留。

## 覆盖升级与数据

`ReviewEntry` 增加可选 `releaseDate`；数据库初始化只使用 `CREATE TABLE IF NOT EXISTS` 与 `ALTER TABLE ADD COLUMN`，升级过程不清空档案。JSON v1–v6 备份格式不变，覆盖安装或解压到新目录后沿用同一应用数据目录：

```text
%APPDATA%\xiaodongge-windows\archive\music_feelings_archive.sqlite
```

既有档案、封面、乐评草稿、推文草稿与分析结果保留；卸载安装版会保留个人档案与用户自建文件。仍建议升级前导出完整 JSON 备份。**推文草稿不在 JSON 备份内**，换机时需另导出 Markdown 稿。

## 验证范围

- `tsc --noEmit` 类型检查通过；`node --test` 65/65 通过（Node.js 24.13.0）。本机默认 Node 22 缺少 `DatabaseSync.setAuthorizer`，对应 6 项 SQLite 用例会失败，验证需使用 Node 24 或以上。
- Vite 生产构建通过；便携包 104 个文件逐项大小与 SHA-256 校验通过；安装器构建脚本核对同一份清单与 104 个文件哈希。
- 真实 Electron 端到端回归 **18 组 + 12 组深浅主题布局全部通过，0 页面错误**：原生 SQLite 启动、六项评分与 v6 导出、保存取消与原子写、批量保存冲突、草稿持久化与重启恢复、隔离内存库恢复预演、v1–v6 导入与撤销、故障回滚、原生恢复日志、月报／年度标本册生成、离线冷启动与便携目录搬移。
- 修复一处移植缺陷：恢复预演的 `INSERT INTO ReviewEntry` 原为 26 列，与新增 `releaseDate` 后的 27 个绑定值不一致，会报 `column index out of range`；现已补齐列与占位符，回归通过。
- 验收合成夹具的 `firstListenedAt` 与记录时间对齐，使双口径月报／年报下的既有月份断言继续有效。

安装器脚本本次未改动（仅由 `package.json` 注入版本号），独立身份下的安装／覆盖升级／卸载回归在 v3.1.1 已验收，本轮未重复执行。

## 已知限制

- **安装包与便携包均未签名**。SignPath Foundation 申请按此前决定保持暂停，尚未取得发布者证书；文件名中的 `unsigned` 表示未签名，请以 Windows 文件属性的数字签名为准。没有自动更新或云同步。
- 公众号后台导入 `.md` 后的最终样式、图片上传与微信实际粘贴，需在你的编辑器中确认；桌面版没有系统分享菜单，「分享 MD 文件」只打开导出文件夹。
- 系统播放封面已在网易云与酷狗实播验收，其他播放器未逐款实测；OCR 语言取决于系统已安装的语言包。Windows 10 与 Android 备份跨端迁移仍需实际设备验收。
- 构建需要 PowerShell 7；若本机 `pwsh.exe` 不在 PATH，可通过 `CODEX_POWERSHELL` 环境变量指向便携版可执行文件，GitHub 托管构建的默认行为不变。

历史版本：[v3.1.1](https://github.com/Yvesyzy/xiaodongge-windows/releases/tag/v3.1.1)。
