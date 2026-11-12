# Windows 播放封面原样保留

Yves 明确要求“读取到啥就提取啥”。按默认执行授权直接修正：播放器经 Windows 媒体会话提供的图片，保留原始字节、格式和尺寸，不缩放、不重新编码、不联网另找图。

工作目录 `D:\codex\workspaces\xiaodongge-windows`；输入为当前原生/前端/验收源码和媒体流。Node 24.13.0、PowerShell 7.6.5 调度、系统 Windows PowerShell 5.1 运行 WinRT。输出为 Windows 3.2.1 源码、独立 `release/codex_windows_raw_cover_*` 验收及便携包。保留已有所有非本轮变更和 3.2.0 交付。

- [x] 原生仅做有界读流、图片解码头校验和格式识别，返回同一流的原始字节。保留 4 MiB、20 MP、4.5 秒保护；超限跳过图片，不能静默缩小。同步 IPC 缓冲到足以携带 4 MiB 图片的 Base64 JSON。
- [x] 前端取消 512 上限，按相同像素和字节预算验证；现有作品身份绑定、草稿、手动封面优先和无图降级保持。草稿/SQLite 不转码。
- [x] 更新最小真实 WinRT 检查：比较输入文件与输出 Base64 解码后 SHA-256，覆盖大于 512 的 PNG、JPEG及其他可安全显示格式、透明度/比例、小图、坏图、体积/像素/超时边界。Electron 用大于 512 的封面验证预览、草稿/备份及 SQLite 原字节往返，沿用已有竞态断言。
- [x] 构建 3.2.1，验证最终包和可用播放器；更新说明/交接。自动清理本轮已无用途的合成 profile/中间物，保留最终包和原字节验收记录。旧 3.2.0 保留，不修改个人档案或重试签名申请。

验收标准：有效原图输出字节与输入一致；不把“原样保存”宣称为取得播放器没有提供的高清源图。最小检查为 `powershell.exe -NoProfile -File scripts/codex_check_windows_artwork.ps1`、类型检查、桌面构建和 `node scripts/codex_check_windows_cover.mjs`。
