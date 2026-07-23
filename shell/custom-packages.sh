#!/bin/bash
# MzWrt ARM 默认插件（ImmortalWrt 24.10 / IPK）
# ARM 分支为小存储设备优化；默认集成常用路由插件。
CUSTOM_PACKAGES=""
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-store luci-i18n-quickstart-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-partexp luci-i18n-partexp-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-turboacc"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-openclash"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-passwall"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-upnp"
