#!/bin/sh
# 该脚本为immortalwrt首次启动时 运行的脚本 即 /etc/uci-defaults/99-custom.sh 也就是说该文件在路由器内 重启后消失 只运行一次

# 定义日志文件路径
LOGFILE="/etc/config/uci-defaults-log.txt"
echo "--- 99-custom.sh 脚本开始执行于 $(date) ---" > $LOGFILE

# --- 1. 设置编译作者信息和设备名称 ---
# 更改固件描述 (DISTRIB_DESCRIPTION)
RELEASE_FILE="/etc/openwrt_release"
NEW_DESCRIPTION="Packaged by Mr.Zhang"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$RELEASE_FILE"
echo "已设置固件描述为: $NEW_DESCRIPTION" >> $LOGFILE

# 更改设备名称 (Hostname) 为 Mz.WRT
NEW_HOSTNAME="Mz.WRT"
uci set system.@system[0].hostname="$NEW_HOSTNAME"
echo "已设置主机名为: $NEW_HOSTNAME" >> $LOGFILE
# uci commit 将在脚本末尾统一执行

# --- 2. 初始网络和系统设置 ---

# 设置默认防火墙规则，方便虚拟机首次访问 WebUI (允许 LAN 输入)
uci set firewall.@zone[1].input='ACCEPT'
echo "已设置 LAN zone input 为 ACCEPT" >> $LOGFILE

# 设置主机名映射，解决安卓原生 TV 无法联网的问题
uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"
echo "已添加 time.android.com 域名映射" >> $LOGFILE

# 检查 PPPoE 配置文件是否存在
SETTINGS_FILE="/etc/config/pppoe-settings"
if [ ! -f "$SETTINGS_FILE" ]; then
    echo "PPPoE settings file not found. Skipping." >> $LOGFILE
else
   # 读取pppoe信息(由build.sh写入)
   . "$SETTINGS_FILE"
fi

# 设置子网掩码 
uci set network.lan.netmask='255.255.255.0'
echo "已设置 LAN 子网掩码为 255.255.255.0" >> $LOGFILE

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

# --- 3. Docker 防火墙规则设置 ---

# 若安装了dockerd 则设置docker的防火墙规则
# 扩大docker涵盖的子网范围 '172.16.0.0/12'
# 方便各类docker容器的端口顺利通过防火墙 
if command -v dockerd >/dev/null 2>&1; then
    echo "检测到 Docker，正在配置防火墙规则..." >> $LOGFILE
    FW_FILE="/etc/config/firewall"

    # 删除所有名为 docker 的 zone
    uci delete firewall.docker

    # 先获取所有 forwarding 索引，倒序排列删除
    # 注意：这里使用 uci delete @forwarding[index] 会更安全，但您的 sed/grep 逻辑也可用
    for idx in $(uci show firewall | grep "=forwarding" | cut -d[ -f2 | cut -d] -f1 | sort -rn); do
        src=$(uci get firewall.@forwarding[$idx].src 2>/dev/null)
        dest=$(uci get firewall.@forwarding[$idx].dest 2>/dev/null)
        # echo "Checking forwarding index $idx: src=$src dest=$dest" >> $LOGFILE # 调试信息
        if [ "$src" = "docker" ] || [ "$dest" = "docker" ]; then
            echo "Deleting forwarding @forwarding[$idx]" >> $LOGFILE
            uci delete firewall.@forwarding[$idx]
        fi
    done
    # 提交删除
    uci commit firewall
    
    # 追加新的 zone + forwarding 配置 (直接修改 /etc/config/firewall)
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
    echo "Docker 防火墙规则配置完成。" >> $LOGFILE

else
    echo "未检测到 Docker，跳过防火墙配置。" >> $LOGFILE
fi

# --- 4. 远程访问设置 ---

# 设置所有网口可访问网页终端 (删除 ttyd 限制)
uci delete ttyd.@ttyd[0].interface
echo "已设置 ttyd 可通过所有网口访问" >> $LOGFILE

# 设置所有网口可连接 SSH (删除 dropbear 限制)
uci set dropbear.@dropbear[0].Interface=''
echo "已设置 dropbear 可通过所有网口访问" >> $LOGFILE

# 统一提交所有 UCI 更改 (防火墙已在 Docker 处提交，这里提交其他更改)
uci commit

echo "--- 99-custom.sh 脚本执行完毕 ---" >> $LOGFILE

exit 0
