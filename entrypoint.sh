#!/bin/sh

set -euo pipefail

USER_NAME=qbittorrent
PROFILE_PATH=/config
CONFIG_FILE="${PROFILE_PATH}/qBittorrent/config/qBittorrent.conf"
DOWNLOADS_PATH=/downloads

if [ -n "${PUID:-}" ] && [ "${PUID}" -ne "$(id -u "${USER_NAME}")" ]; then
  sed -i "s/^${USER_NAME}:x:[0-9]*:/${USER_NAME}:x:${PUID}:/" /etc/passwd
fi

if [ -n "${PGID:-}" ] && [ "${PGID}" -ne "$(id -g "${USER_NAME}")" ]; then
  sed -i "s/^\(${USER_NAME}:x:[0-9]*\):[0-9]*:/\1:${PGID}:/" /etc/passwd
  sed -i "s/^${USER_NAME}:x:[0-9]*:/${USER_NAME}:x:${PGID}:/" /etc/group
fi

if [ ! -f "${CONFIG_FILE}" ]; then
  mkdir -p "${CONFIG_FILE%/*}"
  cat <<EOF >"${CONFIG_FILE}"
[LegalNotice]
Accepted=true

[Preferences]
Connection\PortRangeMin=8999
Downloads\SavePath=${DOWNLOADS_PATH}
Downloads\TempPath=${DOWNLOADS_PATH}/temp
EOF
fi

if [ -d "${DOWNLOADS_PATH}" ]; then
  if [ "$(stat -c %u "${DOWNLOADS_PATH}")" -ne "$(id -u "${USER_NAME}")" ]; then
    chown "${USER_NAME}:" "${DOWNLOADS_PATH}"
  fi
fi

if [ -d "${PROFILE_PATH}" ]; then
  if [ "$(stat -c %u "${PROFILE_PATH}")" -ne "$(id -u "${USER_NAME}")" ]; then
    chown -R "${USER_NAME}:" "${PROFILE_PATH}"
  fi
fi

if [ -n "${UMASK:-}" ]; then
  umask "${UMASK}"
fi

exec su-exec "${USER_NAME}" qbittorrent-nox --profile="${PROFILE_PATH}" "$@"
