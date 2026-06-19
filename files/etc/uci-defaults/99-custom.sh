#!/bin/sh
# MzWrt first-boot customization.
LOGFILE="/etc/config/uci-defaults-log.txt"
echo "Starting MzWrt customization at $(date)" >> "$LOGFILE"

uci set system.@system[0].hostname='MzWrt'
uci commit system

SETTINGS_FILE="/etc/config/pppoe-settings"
if [ -f "$SETTINGS_FILE" ]; then
    . "$SETTINGS_FILE"
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

if [ "$count" -eq 1 ]; then
    uci set network.lan.proto='dhcp'
    uci -q delete network.lan.ipaddr
    uci -q delete network.lan.netmask
    uci -q delete network.lan.gateway
    uci -q delete network.lan.dns
    uci commit network
elif [ "$count" -gt 1 ]; then
    wan_ifname=$(echo "$ifnames" | awk '{print $1}')
    lan_ifnames=$(echo "$ifnames" | cut -d ' ' -f2-)

    uci set network.wan=interface
    uci set network.wan.device="$wan_ifname"
    uci set network.wan.proto='dhcp'
    uci set network.wan6=interface
    uci set network.wan6.device="$wan_ifname"
    uci set network.wan6.proto='dhcpv6'

    section=$(uci show network | awk -F '[.=]' '/\.@?device\[\d+\]\.name=.br-lan.$/ {print $2; exit}')
    if [ -n "$section" ]; then
        uci -q delete "network.$section.ports"
        for port in $lan_ifnames; do
            uci add_list "network.$section.ports"="$port"
        done
    fi

    IP_VALUE_FILE="/etc/config/custom_router_ip.txt"
    CUSTOM_IP='192.168.100.1'
    [ -f "$IP_VALUE_FILE" ] && CUSTOM_IP=$(cat "$IP_VALUE_FILE")
    uci set network.lan.proto='static'
    uci set network.lan.netmask='255.255.255.0'
    uci set network.lan.ipaddr="$CUSTOM_IP"

    if [ "$enable_pppoe" = "yes" ]; then
        uci set network.wan.proto='pppoe'
        uci set network.wan.username="$pppoe_account"
        uci set network.wan.password="$pppoe_password"
        uci set network.wan.peerdns='1'
        uci set network.wan.auto='1'
        uci set network.wan6.proto='none'
    fi
    uci commit network
fi

FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="MzWrt - Packaged by Mr.Zhang"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
