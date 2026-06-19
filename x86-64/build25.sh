#!/bin/bash
set -e

source shell/apk-custom-packages.sh
echo "TurboACC: ImmortalWrt 25.12 APK 仓库暂未提供兼容包，本次构建自动跳过。"

mkdir -p /home/build/immortalwrt/files/etc/config
cat <<EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

if [ -n "$CUSTOM_PACKAGES" ]; then
  echo "同步 25.12 APK 第三方软件包"
  git clone --depth=1 https://github.com/wukongdaily/apk.git /tmp/store-apk-repo
  mkdir -p /home/build/immortalwrt/extra-packages
  cp -r /tmp/store-apk-repo/run/x86/* /home/build/immortalwrt/extra-packages/
  sh shell/apk-prepare-packages.sh
  find /home/build/immortalwrt/packages -type f -name "*.apk" -maxdepth 1 -print
fi

PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-theme-argon luci-app-argon-config luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filemanager-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"
PACKAGES="$PACKAGES luci-app-openclash"
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"

if [ "$INCLUDE_DOCKER" = "yes" ]; then
  PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
fi

mkdir -p files/etc/openclash/core
wget -qO- \
  https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64-v1.tar.gz \
  | tar xOvz > files/etc/openclash/core/clash_meta
chmod +x files/etc/openclash/core/clash_meta
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat \
  -O files/etc/openclash/GeoIP.dat
wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat \
  -O files/etc/openclash/GeoSite.dat
OPENCLASH_URL=$(curl -fsSL https://api.github.com/repos/vernesong/OpenClash/releases/latest \
  | grep "browser_download_url.*apk" | head -n1 | cut -d '"' -f 4)
wget -q "$OPENCLASH_URL" -P /home/build/immortalwrt/packages/

echo "MzWrt 25.12 packages: $PACKAGES"
make image PROFILE="generic" PACKAGES="$PACKAGES" \
  FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE="$PROFILE"
