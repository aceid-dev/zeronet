#!/bin/sh
set -eu

data_dir="${ZERONET_DATA_DIR}"
config_file="${ZERONET_CONFIG_FILE}"
ui_hosts="${ZERONET_UI_HOSTS}"

if [ -n "${ZERONET_UI_EXTRA_HOSTS}" ]; then
  if [ -n "$ui_hosts" ]; then
    ui_hosts="$ui_hosts ${ZERONET_UI_EXTRA_HOSTS}"
  else
    ui_hosts="${ZERONET_UI_EXTRA_HOSTS}"
  fi
fi

mkdir -p "$data_dir"

if [ "${ENABLE_TOR}" = "1" ] || [ "${ENABLE_TOR}" = "true" ]; then
  tor &
fi

# shellcheck disable=SC1091
. /zeronet/venv/bin/activate

set -- \
  python3 zeronet.py \
  --ui_ip "${ZERONET_UI_IP}" \
  --ui_port "${ZERONET_UI_PORT}" \
  --fileserver_port "${ZERONET_FILESERVER_PORT}" \
  --config_file "$config_file" \
  --data_dir "$data_dir"

if [ -n "$ui_hosts" ]; then
  # shellcheck disable=SC2086
  set -- "$@" --ui_host $ui_hosts
fi

if [ -n "${ZERONET_EXTRA_ARGS}" ]; then
  # shellcheck disable=SC2086
  set -- "$@" $ZERONET_EXTRA_ARGS
fi

exec "$@"
