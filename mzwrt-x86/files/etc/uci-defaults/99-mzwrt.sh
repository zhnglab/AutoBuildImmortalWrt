#!/bin/sh

uci set system.@system[0].hostname='MzWrt'
uci commit system

SETTINGS_FILE="/etc/config/mzwrt-settings"
[ -f "$SETTINGS_FILE" ] && . "$SETTINGS_FILE"
custom_router_ip="${custom_router_ip:-192.168.88.1}"

physical_if_count=0
for iface_path in /sys/class/net/*; do
    iface="${iface_path##*/}"
    [ "$iface" = "lo" ] && continue
    [ -e "$iface_path/device" ] || continue
    case "$iface" in
        eth*|en*) physical_if_count=$((physical_if_count + 1)) ;;
    esac
done

if [ "$physical_if_count" -eq 1 ]; then
    uci set network.lan.proto='dhcp'
    uci -q delete network.lan.ipaddr
    uci -q delete network.lan.netmask
    uci -q delete network.lan.gateway
    uci -q delete network.lan.dns
else
    uci set network.lan.proto='static'
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
release_version=""
if [ -f "$FILE_PATH" ]; then
    release_version=$(sed -n "s/^DISTRIB_RELEASE='\([^']*\)'.*/\1/p" "$FILE_PATH")
fi
if [ -z "$release_version" ] && [ -f /usr/lib/os-release ]; then
    release_version=$(sed -n 's/^VERSION_ID="\{0,1\}\([^" ]*\)"\{0,1\}$/\1/p' /usr/lib/os-release)
fi
[ -n "$release_version" ] || release_version="24.10.4"
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
fi

exit 0
