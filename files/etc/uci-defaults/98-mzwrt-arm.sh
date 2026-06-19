#!/bin/sh

uci set system.@system[0].hostname='MzWrt'
uci commit system

for section in $(uci show wireless 2>/dev/null | sed -n "s/^\(wireless\.[^.]*\)=wifi-iface$/\1/p"); do
    uci set "$section.ssid=MzWRT"
done
uci commit wireless

FILE_PATH="/etc/openwrt_release"
NEW_DESCRIPTION="MzWrt - Packaged by Mr.Zhang"
if [ -f "$FILE_PATH" ]; then
    sed -i "s/DISTRIB_DESCRIPTION='[^']*'/DISTRIB_DESCRIPTION='$NEW_DESCRIPTION'/" "$FILE_PATH"
fi

exit 0
