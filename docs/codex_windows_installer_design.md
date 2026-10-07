# Windows 安装包方案与执行计划

## 交付范围

使用 Inno Setup 7 包装已经通过验收的 Windows x64 便携目录，不增加应用依赖或修改业务逻辑。安装身份固定为 `xiaodongge.windows`，每用户安装至 `%LOCALAPPDATA%\Programs\xiaodongge-windows`，提供开始菜单入口、可选桌面快捷方式和系统卸载入口。

个人档案继续使用 `%APPDATA%\xiaodongge-windows`。升级复用安装身份；卸载只移除安装器登记的程序文件和快捷方式，不删除档案、草稿或用户自行放入的文件。便携版与安装版使用同一档案目录，不应同时运行。

## 签名约束

正式签名使用 Windows 证书存储中有私钥的代码签名证书，按完整指纹选择。签名程序、安装器和卸载器，使用 SHA-256 和 RFC 3161 时间戳，随后检查可信链、发布者指纹和时间戳。Electron 自带的供应商签名不代表本应用已签名。

默认构建要求签名证书；仅显式指定 `-AllowUnsigned` 才生成标有 `unsigned` 的未签名安装包。不创建自签名证书、不安装根证书、不将证书密码放进命令行、源码或 Git。PFX 应由持有人通过系统证书导入界面导入个人证书存储，再提供指纹。

## 实施与验收

1. 核对便携目录清单中每个文件的大小和 SHA-256，拒绝缺失、额外文件或越界路径。
2. 加入 Inno Setup 脚本和 PowerShell 构建入口；仅操作新的暂存副本并更新使用说明，保留已发布便携包。
3. 使用独立安装身份、安装目录、开始菜单组和应用 profile，验收静默安装、真实 Electron 启动、覆盖升级和卸载。
4. 检查升级后合成 SQLite 记录和 Chromium 存储仍可读取；卸载后合成个人数据与用户自建文件仍在，系统卸载登记、快捷方式和全部登记程序文件已移除。
5. 更新 README、发行说明和交接记录；发布时明确实际签名状态，保留校验文件和最小验收记录。

## 参数依据

2026-10-07 核对：[Inno Setup 签名](https://jrsoftware.org/ishelp/topic_setup_signtool.htm)、[已签名卸载器](https://jrsoftware.org/ishelp/topic_setup_signeduninstaller.htm)、[每用户权限](https://jrsoftware.org/ishelp/topic_setup_privilegesrequired.htm)、[安装命令行](https://jrsoftware.org/ishelp/topic_setupcmdline.htm)、[卸载命令行](https://jrsoftware.org/ishelp/topic_uninstcmdline.htm)、[Microsoft SignTool](https://learn.microsoft.com/en-us/windows/win32/seccrypto/signtool)。本次复用已安装的 Inno Setup 7.0.2；实际安装验收系统为 Windows 11 x64，其他系统未实机验收。
