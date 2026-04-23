#!/usr/bin/env sh

APP_USER=qbittorrent
CONF_DIR=/config
CONF_FILE=$CONF_DIR/qBittorrent/config/qBittorrent.conf
DL_DIR=/downloads

main() {
  [ -n "$PUID" ] && [ "$PUID" -ne "$(id -u "$APP_USER")" ] &&
    sed -i "s|^\($APP_USER:x\):[^:]*|\1:$PUID|" /etc/passwd

  [ -n "$PGID" ] && [ "$PGID" -ne "$(id -g "$APP_USER")" ] &&
    sed -i "s|^\($APP_USER:x:[^:]*\):[^:]*|\1:$PGID|" /etc/passwd &&
    sed -i "s|^\($APP_USER:x\):[^:]*|\1:$PGID|" /etc/group

  [ -d "${CONF_FILE%/*}" ] || mkdir -p "${CONF_FILE%/*}"

  [ -f "$CONF_FILE" ] || cat <<EOF >"$CONF_FILE"
[LegalNotice]
Accepted=true

[Preferences]
Connection\PortRangeMin=8999
Downloads\SavePath=$DL_DIR
Downloads\TempPath=$DL_DIR/temp
EOF

  [ -d "$DL_DIR" ] && [ "$(stat -c %u "$DL_DIR")" -ne "$(id -u "$APP_USER")" ] &&
    chown "$APP_USER:" "$DL_DIR"

  [ -d "$CONF_DIR" ] && [ "$(stat -c %u "$CONF_DIR")" -ne "$(id -u "$APP_USER")" ] &&
    chown -R "$APP_USER:" "$CONF_DIR"

  [ -z "$UMASK" ] || umask "$UMASK"

  exec su-exec "$APP_USER" qbittorrent-nox --profile="$CONF_DIR" "$@"
}

main "$@"
