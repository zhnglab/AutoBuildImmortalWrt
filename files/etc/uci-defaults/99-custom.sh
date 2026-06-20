#!/bin/sh

LOGFILE="/etc/config/uci-defaults-log.txt"
echo "Starting MzWrt defaults at $(date)" >> "$LOGFILE"

uci set system.@system[0].hostname='MzWrt'
uci set firewall.@zone[1].input='ACCEPT'

uci add dhcp domain
uci set "dhcp.@domain[-1].name=time.android.com"
uci set "dhcp.@domain[-1].ip=203.107.6.88"

SETTINGS_FILE="/etc/config/pppoe-settings"
if [ -f "$SETTINGS_FILE" ]; then
    . "$SETTINGS_FILE"
else
    echo "PPPoE settings file not found. Skipping." >> "$LOGFILE"
fi

ifnames=""
for iface in /sys/class/net/*; do
    iface_name=$(basename "$iface")
    if [ -e "$iface/device" ] && echo "$iface_name" | grep -Eq '^eth|^en'; then
        ifnames="$ifnames $iface_name"
    fi
done
ifnames=$(echo "$ifnames" | awk '{$1=$1};1')
count=$(echo "$ifnames" | wc -w)

board_name=$(cat /tmp/sysinfo/board_name 2>/dev/null || echo "unknown")
case "$board_name" in
    "radxa,e20c"|"friendlyarm,nanopi-r5c")
        wan_ifname="eth1"
        lan_ifnames="eth0"
        ;;
    *)
        wan_ifname=$(echo "$ifnames" | awk '{print $1}')
        lan_ifnames=$(echo "$ifnames" | cut -d ' ' -f2-)
        ;;
esac

if [ "$count" -eq 1 ]; then
    uci set network.lan.proto='dhcp'
    uci -q delete network.lan.ipaddr
    uci -q delete network.lan.netmask
    uci -q delete network.lan.gateway
    uci -q delete network.lan.dns
elif [ "$count" -gt 1 ]; then
    uci set network.wan=interface
    uci set network.wan.device="$wan_ifname"
    uci set network.wan.proto='dhcp'
    uci set network.wan6=interface
    uci set network.wan6.device="$wan_ifname"
    uci set network.wan6.proto='dhcpv6'

    section=$(uci show network | awk -F '[.=]' '/\.@?device\[[0-9]+\]\.name=.br-lan.$/ {print $2; exit}')
    if [ -n "$section" ]; then
        uci -q delete "network.$section.ports"
        for port in $lan_ifnames; do
            uci add_list "network.$section.ports"="$port"
        done
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
        uci set network.wan6.proto='none'
    fi
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

exit 0
