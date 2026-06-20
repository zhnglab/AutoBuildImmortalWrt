#!/bin/bash
# MzWrt ARM 默认插件（ImmortalWrt 25.12 / APK）
# ARM 分支不集成 PassWall；TurboACC 当前没有可用的 25.12 APK。
CUSTOM_PACKAGES=""
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-store luci-i18n-quickstart-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-partexp luci-i18n-partexp-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-openclash"
