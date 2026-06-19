# MzWrt x86

基于 ImmortalWrt ImageBuilder 的 x86-64 固件自动构建项目。

## 构建

进入 **Actions → Build MzWrt x86 → Run workflow**，可手动选择：

- ImmortalWrt 24.10：使用 `opkg`，软件包格式为 `.ipk`。
- ImmortalWrt 25.12：使用新版 `apk`，软件包格式为 `.apk`。

默认主题为 Argon。默认集成 iStore、QuickStart、OpenClash、PassWall、
一键扩容、DiskMan、TTyd、文件管理、SFTP、Samba4 等常用组件。
Docker 可在构建页面选择是否集成。

TurboACC 默认集成到 24.10。由于 25.12 的第三方 APK 仓库目前没有
TurboACC 包，25.12 会自动跳过该插件。

## 默认信息

- 用户名：`root`
- 默认密码：无
- 多网口默认管理地址：`192.168.100.1`
- 固件签名：`MzWrt - Packaged by Mr.Zhang`

## 开源说明

本项目基于 [ImmortalWrt](https://github.com/immortalwrt/immortalwrt) 及其
ImageBuilder，并使用 OpenClash、PassWall、iStore、Argon、TurboACC 等
开源项目。相关软件版权归各自作者所有。

本仓库继续使用 GPL-3.0 许可证。
