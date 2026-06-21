#!/bin/bash
# 临时构建配置：MzWrt ARM N60 Pro（PassWall，无 OpenClash）
CUSTOM_PACKAGES=""
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-store luci-i18n-quickstart-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-partexp luci-i18n-partexp-zh-cn"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES luci-app-turboacc"
CUSTOM_PACKAGES="$CUSTOM_PACKAGES xray-core sing-box hysteria luci-i18n-passwall-zh-cn"
