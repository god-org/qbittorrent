#!/bin/sh

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
[LegalNotice]
Accepted=true

[Preferences]
Connection\PortRangeMin=8999
Downloads\SavePath=$downloadsPath
Downloads\TempPath=$downloadsPath/temp
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

exec doas -u qbittorrent qbittorrent-nox --profile="$profilePath" "$@"
