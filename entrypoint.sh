#!/bin/sh

set -euo pipefail

PUID=${PUID:-1000}
PGID=${PGID:-1000}
UMASK=${UMASK:-022}
DOWNLOADSPATH=/downloads
PROFILEPATH=/config
QBTCONFIGFILE=$PROFILEPATH/qBittorrent/config/qBittorrent.conf

if [ $PUID != $(id -u qbittorrent) ]; then
    sed -i "s/^qbittorrent:x:[0-9]*:/qbittorrent:x:$PUID:/g" /etc/passwd
fi

if [ $PGID != $(id -g qbittorrent) ]; then
    sed -i "s/^\(qbittorrent:x:[0-9]*\):[0-9]*:/\1:$PGID:/g" /etc/passwd
    sed -i "s/^qbittorrent:x:[0-9]*:/qbittorrent:x:$PGID:/g" /etc/group
fi

if [ ! -f $QBTCONFIGFILE ]; then
    mkdir -p $(dirname $QBTCONFIGFILE)
    cat <<EOF >$QBTCONFIGFILE
[LegalNotice]
Accepted=true

[Preferences]
Connection\PortRangeMin=8999
Downloads\SavePath=$DOWNLOADSPATH
Downloads\TempPath=$DOWNLOADSPATH/temp
EOF
fi

if [ -d $DOWNLOADSPATH ] && [ $(stat -c %u $DOWNLOADSPATH) != $PUID ]; then
    chown qbittorrent:qbittorrent $DOWNLOADSPATH
fi

if [ -d $PROFILEPATH ] && [ $(stat -c %u $PROFILEPATH) != $PUID ]; then
    chown qbittorrent:qbittorrent -R $PROFILEPATH
fi

if [ $UMASK != 022 ]; then
    umask $UMASK
fi

exec su-exec qbittorrent qbittorrent-nox --profile=$PROFILEPATH "$@"
