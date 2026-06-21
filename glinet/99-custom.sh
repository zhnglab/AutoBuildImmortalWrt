#!/bin/sh

LOGFILE="/etc/config/uci-defaults-log.txt"
echo "Starting MzWrt ARM wireless defaults at $(date)" >> "$LOGFILE"

uci set system.@system[0].hostname='MzWrt'
uci set firewall.@zone[1].input='ACCEPT'

for section in $(uci show wireless 2>/dev/null | sed -n "s/^\(wireless\.[^.]*\)=wifi-iface$/\1/p"); do
    uci set "$section.ssid=MzWRT"
done

uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"

SETTINGS_FILE="/etc/config/pppoe-settings"
if [ -f "$SETTINGS_FILE" ]; then
    . "$SETTINGS_FILE"
else
    echo "PPPoE settings file not found. Skipping." >> "$LOGFILE"
fi

IP_VALUE_FILE="/etc/config/custom_router_ip.txt"
if [ -s "$IP_VALUE_FILE" ]; then
    CUSTOM_IP=$(cat "$IP_VALUE_FILE")
else
    CUSTOM_IP="192.168.88.1"
fi
uci set network.lan.proto='static'
uci set network.lan.ipaddr="$CUSTOM_IP"
uci set network.lan.netmask='255.255.255.0'

if [ "$enable_pppoe" = "yes" ]; then
    uci set network.wan.proto='pppoe'
    uci set network.wan.username="$pppoe_account"
    uci set network.wan.password="$pppoe_password"
    uci set network.wan.peerdns='1'
    uci set network.wan.auto='1'
fi

uci -q delete ttyd.@ttyd[0].interface
uci set dropbear.@dropbear[0].Interface=''
uci commit

FILE_PATH="/etc/openwrt_release"
release_version=""
if [ -f "$FILE_PATH" ]; then
    release_version=$(sed -n "s/^DISTRIB_RELEASE='\([^']*\)'.*/\1/p" "$FILE_PATH")
fi
if [ -z "$release_version" ] && [ -f /usr/lib/os-release ]; then
    release_version=$(sed -n 's/^VERSION_ID="\{0,1\}\([^" ]*\)"\{0,1\}$/\1/p' /usr/lib/os-release)
fi
[ -n "$release_version" ] || release_version="unknown"
NEW_DESCRIPTION="ImmortalWrt ${release_version} By Mr.Zhang"

if [ -f "$FILE_PATH" ]; then
    sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"
fi

OS_RELEASE="/usr/lib/os-release"
if [ -f "$OS_RELEASE" ]; then
    if grep -q '^PRETTY_NAME=' "$OS_RELEASE"; then
        sed -i "s|^PRETTY_NAME=.*|PRETTY_NAME=\"$NEW_DESCRIPTION\"|" "$OS_RELEASE"
    else
        echo "PRETTY_NAME=\"$NEW_DESCRIPTION\"" >> "$OS_RELEASE"
    fi
    if grep -q '^OPENWRT_RELEASE=' "$OS_RELEASE"; then
        sed -i "s|^OPENWRT_RELEASE=.*|OPENWRT_RELEASE=\"$NEW_DESCRIPTION\"|" "$OS_RELEASE"
    fi
fi

cat > /etc/banner <<'EOF'
 __  __      __        __     _
|  \/  | ____\ \      / /_ __| |_
| |\/| ||_  / \ \ /\ / /| '__| __|
| |  | | / /   \ V  V / | |  | |_
|_|  |_|/___|   \_/\_/  |_|   \__|

         MzWrt ARM by Mr.Zhang
EOF

if command -v dockerd >/dev/null 2>&1; then
    FW_FILE="/etc/config/firewall"
    uci -q delete firewall.docker
    for idx in $(uci show firewall | grep "=forwarding" | cut -d[ -f2 | cut -d] -f1 | sort -rn); do
        src=$(uci get firewall.@forwarding[$idx].src 2>/dev/null)
        dest=$(uci get firewall.@forwarding[$idx].dest 2>/dev/null)
        if [ "$src" = "docker" ] || [ "$dest" = "docker" ]; then
            uci delete firewall.@forwarding[$idx]
        fi
    done
    uci commit firewall
    cat <<'EOF' >> "$FW_FILE"

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
fi

exit 0
