FROM alpine:3.10 AS builder

ARG LIBBT_BRANCH QBT_BRANCH

COPY --link entrypoint.sh /opt/

RUN <<EOF
set -euxo pipefail
thread_count=$(nproc)
apk --no-cache upgrade
apk --no-cache add -t build-dependencies \
  autoconf automake boost-dev boost-static build-base \
  cmake geoip-dev git libtool openssl-dev pkgconfig \
  qt5-qtbase-dev qt5-qtsvg-dev qt5-qttools-dev zlib-dev
git clone -b "${LIBBT_BRANCH:-master}" --recurse-submodules --depth=1 --single-branch --shallow-submodules https://github.com/arvidn/libtorrent /tmp/libtorrent
cd /tmp/libtorrent
cmake \
  -DBUILD_SHARED_LIBS=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_CXX_STANDARD=14 \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DCMAKE_INTERPROCEDURAL_OPTIMIZATION=ON \
  -Ddeprecated-functions=OFF
make -j"${thread_count}" install
git clone -b "${QBT_BRANCH:-master}" --depth=1 --single-branch https://github.com/qbittorrent/qBittorrent /tmp/qBittorrent
cd /tmp/qBittorrent
./configure --prefix=/usr --disable-gui
make -j"${thread_count}" install
ldd /usr/bin/qbittorrent-nox | sort -f
cp -af /usr/bin/qbittorrent-nox /opt/
chmod -R +x /opt
apk del --purge build-dependencies
rm -rf /tmp/* /tmp/.[!.]* /var/cache/apk/* /var/cache/apk/.[!.]*
EOF

FROM alpine:3.10

RUN --mount=type=bind,from=builder,source=/opt,target=/opt <<EOF
set -euxo pipefail
apk --no-cache upgrade
apk --no-cache add qt5-qtbase su-exec tini
cp -af /opt/entrypoint.sh /
cp -af /opt/qbittorrent-nox /usr/bin/
adduser -DH -s /sbin/nologin -u 1000 qbittorrent
EOF

ENTRYPOINT ["tini", "-g", "--", "/entrypoint.sh"]
