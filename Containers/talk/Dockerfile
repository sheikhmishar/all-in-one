FROM nats:2.9.18-scratch as nats
FROM strukturag/nextcloud-spreed-signaling:1.1.2 as signaling
FROM ghcr.io/processone/eturnal:x.x.x-otpxx AS eturnal
FROM alpine:3.18.2

COPY --from=eturnal   /opt/eturnal                        /opt/eturnal
COPY --from=nats      /nats-server                        /usr/local/bin/nats-server
COPY --from=signaling /usr/bin/nextcloud-spreed-signaling /usr/local/bin/nextcloud-spreed-signaling

COPY --chmod=775 cron.sh          /cron.sh
COPY --chmod=775 start.sh         /start.sh
COPY --chmod=664 supervisord.conf /supervisord.conf

RUN set -ex; \
    apk add --no-cache \
        ca-certificates \
        tzdata \
        bash \
        janus-gateway \
        openssl \
        supervisor \
        bind-tools \
        netcat-openbsd \
        shadow \
        util-linux \
        build-base \
        wget \
        lua5.3-dev \
        luarocks5.3; \
    useradd --system eturnal; \
    luarocks-5.3 install luajson; \
    luarocks-5.3 install ansicolors; \
    ln -s /opt/eturnal/bin/eturnalctl /usr/local/bin/eturnalctl; \
    ln -s /opt/eturnal/bin/stun /usr/local/bin/stun; \
    rename -v ".jcfg.sample" ".jcfg" /etc/janus/*.sample; \
    apk del --no-cache \
        shadow \
        util-linux \
        build-base \
        wget \
        lua5.3-dev \
        luarocks5.3; \
    \
# Give root a random password
    echo "root:$(openssl rand -base64 12)" | chpasswd; \
    \
    touch \
        /etc/nats.conf \
        /etc/signaling.conf; \
    echo "listen: 127.0.0.1:4222" | tee /etc/nats.conf; \
    mkdir -p \
        /var/log/supervisord \
        /var/run/supervisord; \
    chown eturnal:eturnal -R \
        /usr \
        /etc/janus \
        /opt/eturnal \
        /etc/nats.conf \
        /etc/signaling.conf \
        /var/log/supervisord \
        /var/run/supervisord;

USER eturnal
ENTRYPOINT ["/start.sh"]
CMD ["supervisord", "-c", "/supervisord.conf"]

HEALTHCHECK CMD (nc -z localhost 8081 && nc -z localhost 8188 && nc -z localhost 4222 && nc -z localhost "$TALK_PORT" && nc -z "$NC_DOMAIN" "$TALK_PORT" && eturnalctl status) || exit 1
LABEL com.centurylinklabs.watchtower.monitor-only="true"
