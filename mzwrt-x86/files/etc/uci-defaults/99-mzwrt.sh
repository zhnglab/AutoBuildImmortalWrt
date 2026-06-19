#!/bin/sh

uci set system.@system[0].hostname='MzWrt'
uci commit system

SETTINGS_FILE="/etc/config/mzwrt-settings"
[ -f "$SETTINGS_FILE" ] && . "$SETTINGS_FILE"

if [ -n "$custom_router_ip" ]; then
    uci set network.lan.ipaddr="$custom_router_ip"
fi

if [ "$enable_pppoe" = "yes" ]; then
    uci set network.wan.proto='pppoe'
    uci set network.wan.username="$pppoe_account"
    uci set network.wan.password="$pppoe_password"
    uci set network.wan.peerdns='1'
    uci set network.wan6.proto='none'
fi
uci commit network

FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="MzWrt - Packaged by Mr.Zhang"
sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"

exit 0
