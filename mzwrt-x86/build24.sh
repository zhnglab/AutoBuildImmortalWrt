#!/bin/bash
set -e
source /home/build/immortalwrt/mzwrt-packages.sh

if [ -n "$CUSTOM_PACKAGES" ]; then
  git clone --depth=1 https://github.com/wukongdaily/store.git /tmp/mzwrt-ipk
  mkdir -p extra-packages
  cp -r /tmp/mzwrt-ipk/run/x86/* extra-packages/
  sh shell/prepare-packages.sh
fi

PACKAGES="curl luci-theme-argon luci-app-argon-config luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filemanager-zh-cn openssh-sftp-server luci-i18n-samba4-zh-cn"
PACKAGES="$PACKAGES xray-core sing-box hysteria luci-i18n-passwall-zh-cn luci-app-openclash"
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"
[ "$INCLUDE_DOCKER" = "yes" ] && PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"

mkdir -p files/etc/openclash/core
wget -qO- https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64-v1.tar.gz | tar xOvz > files/etc/openclash/core/clash_meta
chmod +x files/etc/openclash/core/clash_meta
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O files/etc/openclash/GeoIP.dat
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O files/etc/openclash/GeoSite.dat
OPENCLASH_URL=$(curl -fsSL https://api.github.com/repos/vernesong/OpenClash/releases/latest | grep 'browser_download_url.*ipk' | head -n1 | cut -d '"' -f 4)
wget -q "$OPENCLASH_URL" -P packages/

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE="$PROFILE"
