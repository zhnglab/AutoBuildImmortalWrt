# MzWrt x86 子项目

这是在上游最新 ImmortalWrt-ImageBuilder 源码内新增的独立 x86-64 定制项目，不修改上游原有目录和工作流。

## 构建版本

- ImmortalWrt 24.10：`opkg` / `.ipk`，默认包含 TurboACC。
- ImmortalWrt 25.12：`apk` / `.apk`，当前没有兼容的 TurboACC APK，因此自动跳过。

## 默认组件

Argon、iStore、QuickStart、OpenClash、PassWall、Xray、Sing-box、Hysteria、分区扩容、DiskMan、TTyd、文件管理、SFTP、Samba4；Docker 可在工作流中选择。

## 品牌

- SSH：`MzWrt by Mr.Zhang`
- LuCI 固件描述：`MzWrt - Packaged by Mr.Zhang`
