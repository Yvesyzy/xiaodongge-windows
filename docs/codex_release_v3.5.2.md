# 小懂哥 Windows 桌面版 v3.5.2

发布日期：2026-11-12。版本 `3.5.2`，与手机端 v3.5.2 对应。本次聚焦**跨端迁移**：把整库覆盖式导入升级为可合并导入，并降低备份文件的搬动成本。

## 本次改动

- **合并导入**：备份与恢复页新增「合并导入（跨端迁移建议勾选）」。勾选后以两端并集为目标快照：正式记录、重听、封面按 id 合并，同 id 取 `updatedAt` 较新的一方；年度总结按年份、月度作品按 `年-月` 合并，避免唯一键冲突；本机未保存草稿优先保留。不勾选仍是原来的整库覆盖。差异报告会显示合并后的新增／更新／相同／移除数，隔离预演、恢复日志、撤销与回滚链路沿用原有实现。
- **固定同步文件名**：导出 JSON 时可勾选「跨端同步：使用固定文件名」，文件名固定为 `xiaodongge-from-windows.json`（手机端为 `xiaodongge-from-android.json`），放进云盘或文件传输助手时始终覆盖同一文件，另一端不必在多个时间戳文件里挑。保存时同名文件会被覆盖，请确认目标位置。
- **推文草稿明确提示**：公众号出稿页的推文草稿仍不在 JSON v6 备份内；备份与恢复页现在明确提示迁移前需在出稿页单独导出 Markdown 稿，不再静默遗漏。
- **构建脚本**：便携包压缩与逐文件校验改用仓库已有的 `jszip`，不再依赖 PowerShell 7；安装器脚本兼容系统自带 PowerShell 5.1。安装器内说明文档文件名改为 `codex_user_guide.md`（ASCII，避免非 UTF-8 环境读取 manifest 时乱码）。

合并逻辑放在共享纯模块 `shared/backupMerge.ts`，两端复用；`shared/backupMerge.test.ts` 覆盖两端各自新增、同 id 取新、年度/月度唯一键、草稿与封面规则。

## 2026-11-13 补丁（版本号仍为 3.5.2）

- **写作页标题不再吸顶**：删掉 `.writing-extras > summary` 的 `position: sticky`。之前向下滚动时「补充作品信息、评分与日期（选填）」会一直固定在顶部挡住正文，现在随内容正常滚出视野（实测滚动后该标题 `top` 由 41 变为 -230，计算样式为 `static`）。回归脚本在 12 组窗口/缩放 × 深浅主题里逐项断言该标题不是 `sticky`。
- **覆盖升级不再残留旧文件**：安装器新增 `[InstallDelete]`，升级前先删掉 `{app}\resources\app` 再复制新包。此前带哈希名的旧 JS/CSS 会留在安装目录（例如旧 `index-*.css`），虽然不影响启动，但会让人误判实际加载的样式。用户数据在 `%APPDATA%\xiaodongge-windows`，不受影响。
- **仓库忽略本机安装目录**：安装位置可能落在仓库内（`xiaodongge-windows/`），已加入 `.gitignore`，避免误提交。

## 下载与校验

- [便携 ZIP](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.2/codex_xiaodongge_windows_3.5.2_x64_20261113_012440.zip) — 165,392,724 字节
- [便携 ZIP SHA-256](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.2/codex_xiaodongge_windows_3.5.2_x64_20261113_012440.zip.sha256.txt)

```
b4d6add266be6868de3d0139748ff5ddfb8f7c0bbd596f8936aa446125c8fb07  codex_xiaodongge_windows_3.5.2_x64_20261113_012440.zip
```

- [每用户安装器（自签名）](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.2/codex_xiaodongge_windows_3.5.2_x64_setup_signed_20261113_013704_825.exe) — 122,586,168 字节
- [安装器 SHA-256](https://github.com/Yvesyzy/xiaodongge-windows/releases/download/v3.5.2/codex_xiaodongge_windows_3.5.2_x64_setup_signed_20261113_013704_825.exe.sha256.txt)

```
4efa8f812aea70d89000d0fa3022147c4ef127a38c112966a80921f24a5cead4  codex_xiaodongge_windows_3.5.2_x64_setup_signed_20261113_013704_825.exe
```

## 跨端迁移怎么用

1. 手机端「备份与恢复」勾选「跨端同步：使用固定文件名」→ 导出 JSON，得到 `xiaodongge-from-android.json`。
2. 通过云盘、微信文件传输助手或 U 盘把它放到电脑。
3. Windows 端「备份与恢复」选择该文件，勾选「合并导入」→「预演恢复并查看差异」→ 确认差异 →「合并导入」。
4. 电脑端新增的记录要回手机时，导出 `xiaodongge-from-windows.json`，在手机端同样勾选合并导入。

两端各自新写的记录都会保留；同一条记录以 `updatedAt` 较新的版本为准。推文草稿不会随 JSON 迁移，需在出稿页单独导出 Markdown 稿。

## 覆盖升级与数据

`ReviewEntry` 沿用 `releaseDate`；数据库初始化只使用 `CREATE TABLE IF NOT EXISTS` 与 `ALTER TABLE ADD COLUMN`，JSON v6 备份格式不变（本次未新增字段）。从 v3.5.1 或更早版本覆盖安装或解压到新目录后，沿用同一数据目录 `%APPDATA%\xiaodongge-windows`，既有档案、封面、草稿与分析结果保留。仍建议升级前导出完整 JSON 备份。

## 验证范围

- `tsc --noEmit` 通过；Node 24 单测 **70/70**（含 5 项合并逻辑自检）；Vite 生产构建通过。
- 便携包 104 个文件逐项大小与 SHA-256 校验通过；安装器构建核对同一清单。
- 真实 Electron 回归 **18 组 + 12 组深浅主题布局，0 页面错误**，其中新增「合并导入保留本机全部记录并加入备份新增记录」场景；2026-11-13 补丁另在每组布局里断言写作页扩展区标题不是 `sticky`。
- 2026-11-13 补丁后重跑：12 组布局断言全过；已安装程序 `INSTALLED_APP_WRITE_PASS` / `READ_PASS`（覆盖安装后 SQLite 与 Chromium 写入仍可回读）；安装目录与清单逐文件比对 `missing 0`，旧版残留的 10 个哈希文件已随升级清除。
- 签名版独立身份回归 **4 组全过**（`passed: true`、`signed: true`）：安装文件哈希、SQLite 与 Chromium 写入、覆盖升级数据保留、卸载清除程序且保留用户数据，并验证安装后主程序与卸载器签名。
- 安装器与内嵌主程序带 RFC 3161 时间戳，本机 `Get-AuthenticodeSignature` 为 `Valid`。

## 已知限制

- 安装器使用本机创建的**自签名开发证书**，不是受信任 CA 签发的发布者证书；仅在已导入其根证书的本机验证为有效，其他 Windows 机器会显示签名无效或未知发布者，SmartScreen 提示不会消失。便携 ZIP 未签名。SignPath Foundation 申请已恢复并发出支持求助邮件，尚未获批。
- 推文草稿不在 JSON 备份内；本次选择明确提示而非扩展备份格式，避免改动经过回归验证的恢复事务与撤销链路。
- 未实现后台自动检测同步目录：Android 后台文件访问受限，需要新增权限与 IPC；当前路径仍需手动导出／导入一次。
- 只在 Windows 11 x64 实测；Windows 10 与真机 Android 跨端导入仍待实机验收。

历史版本：[v3.5.1](https://github.com/Yvesyzy/xiaodongge-windows/releases/tag/v3.5.1)、[v3.1.1](https://github.com/Yvesyzy/xiaodongge-windows/releases/tag/v3.1.1)。
