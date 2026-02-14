FROM alpine:3.10 AS builder

ARG LIBBT_BRANCH QBT_BRANCH

RUN set -ex \
    && apk --no-cache upgrade \
    && apk --no-cache add --virtual build-dependencies autoconf automake boost-dev boost-static build-base cmake geoip-dev git libtool openssl-dev pkgconfig qt5-qtbase-dev qt5-qtsvg-dev qt5-qttools-dev zlib-dev \
    && git clone -b "$LIBBT_BRANCH" --recurse-submodules --depth=1 --single-branch --shallow-submodules "https://github.com/arvidn/libtorrent" "/tmp/libtorrent" \
    && cd "/tmp/libtorrent" \
    && cmake -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=14 -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON -Ddeprecated-functions=OFF \
    && make -j"$(nproc)" install \
    && git clone -b "$QBT_BRANCH" --depth=1 --single-branch "https://github.com/qbittorrent/qBittorrent" "/tmp/qBittorrent" \
    && cd "/tmp/qBittorrent" \
    && ./configure --prefix=/usr --disable-gui \
    && make -j"$(nproc)" install \
    && ldd "/usr/bin/qbittorrent-nox" | sort -f \
    && apk del --purge build-dependencies \
    && rm -rf "/tmp/"* "/tmp/".[!.]* "/var/cache/apk/"* "/var/cache/apk/".[!.]*

FROM alpine:3.10 AS dist

RUN set -ex \
    && apk --no-cache upgrade \
    && apk --no-cache add doas qt5-qtbase tini \
    && adduser -DH -s /sbin/nologin -u 1000 qbittorrent \
    && echo "permit nopass :root" >>"/etc/doas.conf"

COPY entrypoint.sh /entrypoint.sh
COPY --from=builder /usr/bin/qbittorrent-nox /usr/bin/qbittorrent-nox

ENTRYPOINT ["tini", "-g", "--", "/entrypoint.sh"]
