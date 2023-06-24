#!/bin/bash

# Variables
if [ -z "$NC_DOMAIN" ]; then
    echo "You need to provide the NC_DOMAIN."
    exit 1
fi

set -x
if [ -n "$(dig "$NC_DOMAIN" A +short | grep -E "^[0-9.]+$" | sort | head -n1)" ]; then
    IPv4_ADDRESS_NC="$(dig "$NC_DOMAIN" A +short | grep -E "^[0-9.]+$" | sort | head -n1)"
fi
if [ -n "$(dig "$NC_DOMAIN" AAAA +short | grep -E "^[0-9a-fA-F:]+$" | sort | head -n1)" ]; then
    IPv6_ADDRESS_NC="$(dig "$NC_DOMAIN" AAAA +short | grep -E "^[0-9a-fA-F:]+$" | sort | head -n1)"
fi
set +x

if grep -q relay_ipv4_addr /opt/eturnal/etc/eturnal.yml; then
    sed -i "s|relay_ipv4_addr.*|relay_ipv4_addr: \"$IPv4_ADDRESS_NC\"|g" /opt/eturnal/etc/eturnal.yml
else
    echo "  relay_ipv4_addr: \"$IPv4_ADDRESS_NC\"" | tee -a /opt/eturnal/etc/eturnal.yml
fi

if grep -q relay_ipv6_addr /opt/eturnal/etc/eturnal.yml; then
    sed -i "s|relay_ipv6_addr.*|relay_ipv6_addr: \"$IPv6_ADDRESS_NC\"|g" /opt/eturnal/etc/eturnal.yml
else
    echo "  relay_ipv6_addr: \"$IPv6_ADDRESS_NC\"" | tee -a /opt/eturnal/etc/eturnal.yml
fi

sed -i '/""/d' /opt/eturnal/etc/eturnal.yml

eturnalctl reload
