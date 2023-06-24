#!/bin/bash

# Variables
if [ -z "$NC_DOMAIN" ]; then
    echo "You need to provide the NC_DOMAIN."
    exit 1
elif [ -z "$TALK_PORT" ]; then
    echo "You need to provide the TALK_PORT."
    exit 1
elif [ -z "$TURN_SECRET" ]; then
    echo "You need to provide the TURN_SECRET."
    exit 1
elif [ -z "$SIGNALING_SECRET" ]; then
    echo "You need to provide the SIGNALING_SECRET."
    exit 1
elif [ -z "$INTERNAL_SECRET" ]; then
    echo "You need to provide the INTERNAL_SECRET."
    exit 1
fi

set -x
if [ -n "$(dig nextcloud-aio-talk A +short | grep -E "^[0-9.]+$" | sort | head -n1)" ]; then
    IPv4_ADDRESS_TALK="$(dig nextcloud-aio-talk A +short | grep -E "^[0-9.]+$" | sort | head -n1)"
fi
if [ -n "$(dig nextcloud-aio-talk AAAA +short | grep -E "^[0-9a-fA-F:]+$" | sort | head -n1)" ]; then
    IPv6_ADDRESS_TALK="$(dig nextcloud-aio-talk AAAA +short | grep -E "^[0-9a-fA-F:]+$" | sort | head -n1)"
fi

if [ -n "$(dig "$NC_DOMAIN" A +short | grep -E "^[0-9.]+$" | sort | head -n1)" ]; then
    IPv4_ADDRESS_NC="$(dig "$NC_DOMAIN" A +short | grep -E "^[0-9.]+$" | sort | head -n1)"
fi
if [ -n "$(dig "$NC_DOMAIN" AAAA +short | grep -E "^[0-9a-fA-F:]+$" | sort | head -n1)" ]; then
    IPv6_ADDRESS_NC="$(dig "$NC_DOMAIN" AAAA +short | grep -E "^[0-9a-fA-F:]+$" | sort | head -n1)"
fi
set +x

# Turn
cat << TURN_CONF > "/opt/eturnal/etc/eturnal.yml"
eturnal:
  listen:
    - ip: "::"
      port: $TALK_PORT
      transport: udp
    - ip: "::"
      port: $TALK_PORT
      transport: tcp
  log_dir: stdout
  log_level: warning
  secret: "$TURN_SECRET"
  relay_ipv4_addr: "$IPv4_ADDRESS_NC"
  relay_ipv6_addr: "$IPv6_ADDRESS_NC"
  whitelist:
  - 127.0.0.1
  - ::1
  - "$IPv4_ADDRESS_TALK"
  - "$IPv6_ADDRESS_TALK"
  blacklist:
  - recommended
TURN_CONF

sed -i '/""/d' /opt/eturnal/etc/eturnal.yml

# Signling
cat << SIGNALING_CONF > "/etc/signaling.conf"
[http]
listen = 0.0.0.0:8081

[app]
debug = false

[sessions]
hashkey = $(openssl rand -hex 16)
blockkey = $(openssl rand -hex 16)

[clients]
internalsecret = ${INTERNAL_SECRET}

[backend]
backends = backend-1
allowall = false
timeout = 10
connectionsperhost = 8

[backend-1]
url = https://${NC_DOMAIN}
secret = ${SIGNALING_SECRET}

[nats]
url = nats://127.0.0.1:4222

[mcu]
type = janus
url = ws://127.0.0.1:8188
SIGNALING_CONF

exec "$@"
