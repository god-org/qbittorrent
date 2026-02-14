#!/bin/sh

DOWNLOADSPATH="/downloads"
PROFILEPATH="/config"
QBTCONFIGFILE="$PROFILEPATH/qBittorrent/config/qBittorrent.conf"

if [ -n "$PUID" ] && [ "$PUID" != "$(id -u qbittorrent)" ]; then
    sed -i "s|^qbittorrent:x:[0-9]*:|qbittorrent:x:$PUID:|g" "/etc/passwd"
fi

if [ -n "$PGID" ] && [ "$PGID" != "$(id -g qbittorrent)" ]; then
    sed -i "s|^\(qbittorrent:x:[0-9]*\):[0-9]*:|\1:$PGID:|g" "/etc/passwd"
    sed -i "s|^qbittorrent:x:[0-9]*:|qbittorrent:x:$PGID:|g" "/etc/group"
fi

if [ ! -f "$QBTCONFIGFILE" ]; then
    mkdir -p "$(dirname "$QBTCONFIGFILE")"

    cat <<EOF >"$QBTCONFIGFILE"
[LegalNotice]
Accepted=true

[Preferences]
Connection\PortRangeMin=8999
Downloads\SavePath=$DOWNLOADSPATH
Downloads\TempPath=$DOWNLOADSPATH/temp
EOF
fi

if [ -d "$DOWNLOADSPATH" ]; then
    chown "qbittorrent":"qbittorrent" "$DOWNLOADSPATH"
fi

if [ -d "$PROFILEPATH" ]; then
    chown "qbittorrent":"qbittorrent" -R "$PROFILEPATH"
fi

if [ -n "$UMASK" ]; then
    umask "$UMASK"
fi

exec doas -u "qbittorrent" qbittorrent-nox --profile="$PROFILEPATH" "$@"
