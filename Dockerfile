FROM alpine:3.10 AS builder
RUN set -ex \
    && apk --no-cache upgrade \
    && apk --no-cache add -t .build autoconf automake boost-dev build-base geoip-dev git libtool openssl-dev pkgconfig qt5-qtbase-dev qt5-qtsvg-dev qt5-qttools-dev zlib-dev \
    && cd /tmp \
    && git clone --branch libtorrent-1_1_14 --depth 1 --recurse-submodules --shallow-submodules https://github.com/arvidn/libtorrent \
    && cd libtorrent \
    && ./autotool.sh && ./configure --prefix=/usr --disable-static --disable-deprecated-functions && make -j$(nproc) && make install \
    && cd .. \
    && git clone --branch release-4.1.9 --depth 1 https://github.com/qbittorrent/qBittorrent \
    && cd qBittorrent \
    && ./configure --prefix=/usr --disable-gui && make -j$(nproc) && make install \
    && cd / \
    && ldd /usr/bin/qbittorrent-nox | sort -f \
    && apk del --purge .build && rm -rf /tmp/* /var/cache/apk/*
FROM alpine:3.10 AS dist
RUN set -ex \
    && apk --no-cache upgrade \
    && apk --no-cache add qt5-qtbase tini \
    && adduser -s /sbin/nologin -D -H -u 1000 qbittorrent
COPY --from=builder /usr/lib /usr/lib
COPY --from=builder /usr/bin/qbittorrent-nox /usr/bin/qbittorrent-nox
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["tini", "-g", "--", "/entrypoint.sh"]
USER qbittorrent
CMD ["qbittorrent-nox", "--profile=/config"]
