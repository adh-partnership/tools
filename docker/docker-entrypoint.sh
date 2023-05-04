#!/usr/bin/env bash

set -e
uid=$(id -u)
gid=$(id -g)

shopt -s dotglob

# Add user based upon passed UID.
if [[ "${uid}" -ne 0 ]]; then
  su-exec 0:0 useradd --uid "${uid}" --system user
fi

su-exec 0:0 chown "${uid}":"${gid}" /home

exec "$@"