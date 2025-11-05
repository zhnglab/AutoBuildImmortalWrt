#!/bin/bash
# Log file for debugging
source shell/custom-packages.sh
echo "第三方软件包: $CUSTOM_PACKAGES"
LOGFILE="/tmp/uci-defaults-log.txt"
echo "Starting 99-custom.sh at $(date)" >> $LOGFILE
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

echo "Create pppoe-settings"
mkdir -p  /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件 yml传入环境变量ENABLE_PPPOE等 写入配置文件 供99-custom.sh读取
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings

if [ -z "$CUSTOM_PACKAGES" ]; then
  echo "⚪️ 未选择 任何第三方软件包"
else
  # ============= 同步第三方插件库==============
  # 同步第三方软件仓库run/ipk
  echo "🔄 正在同步第三方软件仓库 Cloning run file repo..."
  git clone --depth=1 https://github.com/wukongdaily/store.git /tmp/store-run-repo

  # 拷贝 run/x86 下所有 run 文件和ipk文件 到 extra-packages 目录
  mkdir -p /home/build/immortalwrt/extra-packages
  cp -r /tmp/store-run-repo/run/x86/* /home/build/immortalwrt/extra-packages/

  echo "✅ Run files copied to extra-packages:"
  ls -lh /home/build/immortalwrt/extra-packages/*.run
  # 解压并拷贝ipk到packages目录
  sh shell/prepare-packages.sh
  ls -lah /home/build/immortalwrt/packages/
fi

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始构建固件..."

# ============= imm仓库内的插件==============
# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-theme-argon"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
#24.10
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-i18n-passwall-zh-cn"
PACKAGES="$PACKAGES luci-app-openclash"
#PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
PACKAGES="$PACKAGES openssh-sftp-server"
#PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"
# 文件管理器
PACKAGES="$PACKAGES luci-i18n-filemanager-zh-cn"
# 静态文件服务器dufs(推荐)
#PACKAGES="$PACKAGES luci-i18n-dufs-zh-cn"
# ======== shell/custom-packages.sh =======
# 合并imm仓库以外的第三方插件
PACKAGES="$PACKAGES $CUSTOM_PACKAGES"


# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 若构建openclash 则添加内核
if echo "$PACKAGES" | grep -q "luci-app-openclash"; then
    echo "✅ 已选择 luci-app-openclash，添加 openclash core"
    mkdir -p files/etc/openclash/core
    # Download clash_meta
    META_URL="https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz"
    wget -qO- $META_URL | tar xOvz > files/etc/openclash/core/clash_meta
    chmod +x files/etc/openclash/core/clash_meta
    # Download GeoIP and GeoSite
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -O files/etc/openclash/GeoIP.dat
    wget -q https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -O files/etc/openclash/GeoSite.dat
else
    echo "⚪️ 未选择 luci-app-openclash"
fi

#!/bin/bash

# ================== 🧩 自定义固件信息 by Mr.Zhang ================== 
echo "🧩 正在写入自定义版本与界面信息..."

# 动态定义版本号（只到月份）
CUSTOM_DATE=$(date +%Y.%m)
CUSTOM_VERSION="ImmortalWrt Mr.Zhang Edition ${CUSTOM_DATE}"
CUSTOM_AUTHOR="Mr.Zhang"

# 创建必要的目录
mkdir -p /home/build/immortalwrt/files/etc
mkdir -p /home/build/immortalwrt/files/usr/lib/lua/luci/view/themes/argon
mkdir -p /home/build/immortalwrt/files/www/luci-static/resources/view/status

# 1️⃣ 修改 SSH 登录界面信息
cat > /home/build/immortalwrt/files/etc/banner <<'EOF'
-----------------------------------------------------
🧩 ImmortalWrt Custom Build by Mr.Zhang
-----------------------------------------------------
EOF

# 2️⃣ 修改 LuCI 网页底部版权信息
cat > /home/build/immortalwrt/files/usr/lib/lua/luci/view/themes/argon/footer.htm <<EOF
<footer class="footer">
  <div class="container text-center" style="padding:10px 0;">
    ${CUSTOM_VERSION} | Powered by <a href="https://immortalwrt.org/" target="_blank">ImmortalWrt</a> | Customized by ${CUSTOM_AUTHOR}
  </div>
</footer>
EOF

# 3️⃣ 修改状态概览页面中的固件版本信息
mkdir -p /home/build/immortalwrt/files/www/luci-static/resources/view/status
cat > /home/build/immortalwrt/files/www/luci-static/resources/view/status/index.htm <<EOF
<!-- Customizing the firmware version display -->
<script type="text/javascript">
  document.getElementById("distversion").innerHTML = "${CUSTOM_VERSION}";
</script>
EOF

# 输出结果
echo "✅ 自定义信息写入完成："
echo " SSH 登录显示：🧩 ImmortalWrt Custom Build by Mr.Zhang"
echo " LuCI 底部版权：${CUSTOM_VERSION} | Customized by ${CUSTOM_AUTHOR}"
echo " 状态概览固件版本：${CUSTOM_VERSION}"
echo "====================================================="


# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi
