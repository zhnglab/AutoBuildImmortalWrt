#!/bin/sh

for section in $(uci show wireless 2>/dev/null | sed -n "s/^\(wireless\.[^.]*\)=wifi-iface$/\1/p"); do
    uci set "$section.ssid=MzWRT"
done
uci commit wireless

exit 0
