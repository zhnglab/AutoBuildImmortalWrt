#!/bin/bash
# MzWrt x86 默认插件（ImmortalWrt 25.12 / APK）
# TurboACC 当前没有可用的 25.12 APK，因此仅在 24.10 默认集成。
CUSTOM_PACKAGES=""
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-store luci-i18n-quickstart-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-partexp luci-i18n-partexp-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-openclash"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES xray-core sing-box hysteria kmod-nft-socket kmod-nft-tproxy luci-app-passwall2 luci-i18n-passwall2-zh-cn"
