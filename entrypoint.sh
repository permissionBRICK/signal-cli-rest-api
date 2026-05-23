#!/bin/sh

set -x
set -e

[ -z "${SIGNAL_CLI_CONFIG_DIR}" ] && echo "SIGNAL_CLI_CONFIG_DIR environmental variable needs to be set! Aborting!" && exit 1;

usermod -u ${SIGNAL_CLI_UID} signal-api
groupmod -o -g ${SIGNAL_CLI_GID} signal-api

# Fix permissions to ensure backward compatibility if SIGNAL_CLI_CHOWN_ON_STARTUP is not set to "false"
if [ "$SIGNAL_CLI_CHOWN_ON_STARTUP" != "false" ]; then
  echo "Changing ownership of ${SIGNAL_CLI_CONFIG_DIR} to ${SIGNAL_CLI_UID}:${SIGNAL_CLI_GID}"
  chown ${SIGNAL_CLI_UID}:${SIGNAL_CLI_GID} -R ${SIGNAL_CLI_CONFIG_DIR}
else
  echo "Skipping chown on startup since SIGNAL_CLI_CHOWN_ON_STARTUP is set to 'false'"
fi

# Show warning on docker exec
cat <<EOF >> /root/.bashrc
echo "WARNING: signal-cli-rest-api runs as signal-api (not as root!)" 
echo "Run 'su signal-api' before using signal-cli!"
echo "If you want to use signal-cli directly, don't forget to specify the config directory. e.g: \"signal-cli --config ${SIGNAL_CLI_CONFIG_DIR}\""
EOF

cap_prefix="-cap_"
caps="$cap_prefix$(seq -s ",$cap_prefix" 0 $(cat /proc/sys/kernel/cap_last_cap))"

# TODO: check mode
if [ "$MODE" = "json-rpc" ] || [ "$MODE" = "json-rpc-native" ]
then
/usr/bin/jsonrpc2-helper
if [ -n "$JAVA_OPTS" ] ; then
    echo "export JAVA_OPTS='$JAVA_OPTS'" >> /etc/default/supervisor
fi
service supervisor start
supervisorctl start all

# Optional: expose the signal-cli JSON-RPC TCP socket directly to the outside.
# When JSON_RPC_TCP_PORT is set, socat listens on 0.0.0.0:$JSON_RPC_TCP_PORT
# and forwards each accepted connection to the local signal-cli daemon on
# 127.0.0.1:6001. signal-cli daemon accepts multiple concurrent TCP clients,
# so the REST API on 127.0.0.1:6001 keeps working in parallel.
if [ -n "$JSON_RPC_TCP_PORT" ]; then
    case "$JSON_RPC_TCP_PORT" in
        ''|*[!0-9]*)
            echo "JSON_RPC_TCP_PORT must be a number, got '$JSON_RPC_TCP_PORT'" >&2
            exit 1
            ;;
    esac
    JSON_RPC_TCP_BIND="${JSON_RPC_TCP_BIND:-0.0.0.0}"
    echo "Exposing signal-cli JSON-RPC on ${JSON_RPC_TCP_BIND}:${JSON_RPC_TCP_PORT} -> 127.0.0.1:6001"
    socat -d -lf /var/log/signal-cli-jsonrpc-forwarder.log \
        TCP-LISTEN:${JSON_RPC_TCP_PORT},bind=${JSON_RPC_TCP_BIND},fork,reuseaddr \
        TCP:127.0.0.1:6001 &
fi
fi

if [ -z "$MODE" ] || [ "$MODE" = "normal" ] || [ "$MODE" = "native" ]; then
    if [ -n "$JSON_RPC_TCP_PORT" ]; then
        echo "JSON_RPC_TCP_PORT is only valid in MODE=json-rpc or json-rpc-native (MODE='${MODE:-normal}'). Ignoring." >&2
    fi
fi

export HOST_IP=$(hostname -I | awk '{print $1}')

# Start API as signal-api user
exec setpriv --reuid=${SIGNAL_CLI_UID} --regid=${SIGNAL_CLI_GID} --init-groups --inh-caps=$caps signal-cli-rest-api -signal-cli-config=${SIGNAL_CLI_CONFIG_DIR}
