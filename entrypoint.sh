#!/bin/sh -e

downloadsPath="/downloads"
profilePath="/config"
qbtConfigFile="$profilePath/qBittorrent/config/qBittorrent.conf"

if [ -n "$PUID" ] && [ "$PUID" != "$(id -u qbittorrent)" ]; then
    sed -i "s|^qbittorrent:x:[0-9]*:|qbittorrent:x:$PUID:|g" /etc/passwd
fi

if [ -n "$PGID" ] && [ "$PGID" != "$(id -g qbittorrent)" ]; then
    sed -i "s|^\(qbittorrent:x:[0-9]*\):[0-9]*:|\1:$PGID:|g" /etc/passwd
    sed -i "s|^qbittorrent:x:[0-9]*:|qbittorrent:x:$PGID:|g" /etc/group
fi

if [ ! -f "$qbtConfigFile" ]; then
    mkdir -p "$(dirname $qbtConfigFile)"
    cat <<EOF >"$qbtConfigFile"
[BitTorrent]
Session\DefaultSavePath=$downloadsPath
Session\Port=6881
Session\TempPath=$downloadsPath/temp

[LegalNotice]
Accepted=true
EOF
fi

if [ -d "$downloadsPath" ]; then
    chown qbittorrent:qbittorrent "$downloadsPath"
fi

if [ -d "$profilePath" ]; then
    chown qbittorrent:qbittorrent -R "$profilePath"
fi

if [ -n "$UMASK" ]; then
    umask "$UMASK"
fi

exec "$@"
