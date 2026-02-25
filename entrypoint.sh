#!/bin/sh

USER_NAME='qbittorrent'
DOWNLOADS_PATH='/downloads'
PROFILE_PATH='/config'
CONFIG_FILE_PATH="${PROFILE_PATH}/qBittorrent/config/qBittorrent.conf"

sync_ids() {
  puid_val="${PUID:-1000}"
  pgid_val="${PGID:-1000}"

  cur_uid=$(id -u "${USER_NAME}")
  if [ "${cur_uid}" -ne "${puid_val}" ]; then
    sed -i "s/^${USER_NAME}:x:[0-9]*:/${USER_NAME}:x:${puid_val}:/g" /etc/passwd
  fi

  cur_gid=$(id -g "${USER_NAME}")
  if [ "${cur_gid}" -ne "${pgid_val}" ]; then
    sed -i "s/^\(${USER_NAME}:x:[0-9]*\):[0-9]*:/\1:${pgid_val}:/g" /etc/passwd
    sed -i "s/^${USER_NAME}:x:[0-9]*:/${USER_NAME}:x:${pgid_val}:/g" /etc/group
  fi

  unset puid_val pgid_val cur_uid cur_gid
}

init_config() {
  conf_dir="${CONFIG_FILE_PATH%/*}"
  downloads_dir="${DOWNLOADS_PATH}"

  if [ ! -f "${CONFIG_FILE_PATH}" ]; then
    mkdir -p "${conf_dir}"
    cat <<EOF >"${CONFIG_FILE_PATH}"
[LegalNotice]
Accepted=true

[Preferences]
Connection\PortRangeMin=8999
Downloads\SavePath=${downloads_dir}
Downloads\TempPath=${downloads_dir}/temp
EOF
  fi

  unset conf_dir downloads_dir
}

fix_permissions() {
  target_uid="${PUID:-1000}"

  if [ -d "${DOWNLOADS_PATH}" ]; then
    if [ "$(stat -c %u "${DOWNLOADS_PATH}")" -ne "${target_uid}" ]; then
      chown "${USER_NAME}:${USER_NAME}" "${DOWNLOADS_PATH}"
    fi
  fi

  if [ -d "${PROFILE_PATH}" ]; then
    if [ "$(stat -c %u "${PROFILE_PATH}")" -ne "${target_uid}" ]; then
      chown -R "${USER_NAME}:${USER_NAME}" "${PROFILE_PATH}"
    fi
  fi

  unset target_uid
}

main() {
  target_umask="${UMASK:-022}"

  sync_ids
  init_config
  fix_permissions

  if [ "${target_umask}" != '022' ]; then
    umask "${target_umask}"
  fi

  unset target_umask
  unset -f sync_ids init_config fix_permissions main
  unset USER_NAME DOWNLOADS_PATH PROFILE_PATH CONFIG_FILE_PATH

  exec su-exec qbittorrent qbittorrent-nox --profile='/config' "$@"
}

main "$@"
