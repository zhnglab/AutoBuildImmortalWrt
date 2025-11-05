#!/bin/sh
# 该脚本为immortalwrt首次启动时 运行的脚本 即 /etc/uci-defaults/99-custom.sh 也就是说该文件在路由器内 重启后消失 只运行一次
# 设置默认防火墙规则，方便虚拟机首次访问 WebUI
LOGFILE="/etc/config/uci-defaults-log.txt"
uci set firewall.@zone[1].input='ACCEPT'

# 设置主机名映射，解决安卓原生 TV 无法联网的问题
uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"

# 检查配置文件是否存在
SETTINGS_FILE="/etc/config/pppoe-settings"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "PPPoE settings file not found. Skipping." >> $LOGFILE
else
   # 读取pppoe信息(由build.sh写入)
   . "$SETTINGS_FILE"
fi
# 设置子网掩码 
uci set network.lan.netmask='255.255.255.0'
# 设置路由器管理后台地址
IP_VALUE_FILE="/etc/config/custom_router_ip.txt"
if [ -f "$IP_VALUE_FILE" ]; then
    CUSTOM_IP=$(cat "$IP_VALUE_FILE")
    # 设置路由器的管理后台地址
    uci set network.lan.ipaddr=$CUSTOM_IP
    echo "custom router ip is $CUSTOM_IP" >> $LOGFILE
fi


# 判断是否启用 PPPoE
echo "print enable_pppoe value=== $enable_pppoe" >> $LOGFILE
if [ "$enable_pppoe" = "yes" ]; then
    echo "PPPoE is enabled at $(date)" >> $LOGFILE
    # 设置拨号信息
    uci set network.wan.proto='pppoe'                
    uci set network.wan.username=$pppoe_account     
    uci set network.wan.password=$pppoe_password     
    uci set network.wan.peerdns='1'                  
    uci set network.wan.auto='1' 
    echo "PPPoE configuration completed successfully." >> $LOGFILE
else
    echo "PPPoE is not enabled. Skipping configuration." >> $LOGFILE
fi

# 若安装了dockerd 则设置docker的防火墙规则
# 扩大docker涵盖的子网范围 '172.16.0.0/12'
# 方便各类docker容器的端口顺利通过防火墙 
if command -v dockerd >/dev/null 2>&1; then
    echo "检测到 Docker，正在配置防火墙规则..."
    FW_FILE="/etc/config/firewall"

    # 删除所有名为 docker 的 zone
    uci delete firewall.docker

    # 先获取所有 forwarding 索引，倒序排列删除
    for idx in $(uci show firewall | grep "=forwarding" | cut -d[ -f2 | cut -d] -f1 | sort -rn); do
        src=$(uci get firewall.@forwarding[$idx].src 2>/dev/null)
        dest=$(uci get firewall.@forwarding[$idx].dest 2>/dev/null)
        echo "Checking forwarding index $idx: src=$src dest=$dest"
        if [ "$src" = "docker" ] || [ "$dest" = "docker" ]; then
            echo "Deleting forwarding @forwarding[$idx]"
            uci delete firewall.@forwarding[$idx]
        fi
    done
    # 提交删除
    uci commit firewall
    # 追加新的 zone + forwarding 配置
    cat <<EOF >>"$FW_FILE"

config zone 'docker'
  option input 'ACCEPT'
  option output 'ACCEPT'
  option forward 'ACCEPT'
  option name 'docker'
  list subnet '172.16.0.0/12'

config forwarding
  option src 'docker'
  option dest 'lan'

config forwarding
  option src 'docker'
  option dest 'wan'

config forwarding
  option src 'lan'
  option dest 'docker'
EOF

else
    echo "未检测到 Docker，跳过防火墙配置。"
fi

# 设置所有网口可访问网页终端
uci delete ttyd.@ttyd[0].interface

# 设置所有网口可连接 SSH
uci set dropbear.@dropbear[0].Interface=''
uci commit


# ================== 🧩 自定义固件信息 by Mr.Zhang ================== 
echo "🧩 正在写入自定义版本与界面信息..."

# 动态定义版本号（只到月份）
CUSTOM_DATE=$(date +%Y.%m)
CUSTOM_VERSION="ImmortalWrt Mr.Zhang Edition ${CUSTOM_DATE}"
CUSTOM_AUTHOR="Mr.Zhang"

# 创建必要的目录
mkdir -p /etc
mkdir -p /usr/lib/lua/luci/view/themes/argon
mkdir -p /www/luci-static/resources/view/status

# 1️⃣ 修改 SSH 登录界面信息
cat > /etc/banner <<'EOF'
-----------------------------------------------------
🧩 ImmortalWrt Custom Build by Mr.Zhang
-----------------------------------------------------
EOF

# 2️⃣ 修改 LuCI 网页底部版权信息
cat > /usr/lib/lua/luci/view/themes/argon/footer.htm <<EOF
<footer class="footer">
  <div class="container text-center" style="padding:10px 0;">
    ${CUSTOM_VERSION} | Powered by <a href="https://immortalwrt.org/" target="_blank">ImmortalWrt</a> | Customized by ${CUSTOM_AUTHOR}
  </div>
</footer>
EOF

# 3️⃣ 修改状态概览页面中的固件版本信息
cat > /www/luci-static/resources/view/status/index.htm <<EOF
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



exit 0
