#!/usr/bin/env bash
# Home Assistant addon entrypoint: translate /data/options.json into the
# env vars consumed by the upstream entrypoint, then hand off.
set -e

OPTIONS_FILE=/data/options.json

if [ -f "$OPTIONS_FILE" ]; then
    MODE=$(jq -r '.mode // "normal"' "$OPTIONS_FILE")
    LOG_LEVEL=$(jq -r '.log_level // "info"' "$OPTIONS_FILE")
    EXPOSE_JSONRPC=$(jq -r '.expose_jsonrpc // false' "$OPTIONS_FILE")
    AUTO_RECEIVE_SCHEDULE=$(jq -r '.auto_receive_schedule // empty' "$OPTIONS_FILE")
    JSON_RPC_IGNORE_ATTACHMENTS=$(jq -r '.json_rpc_ignore_attachments // empty' "$OPTIONS_FILE")
    JSON_RPC_IGNORE_STORIES=$(jq -r '.json_rpc_ignore_stories // empty' "$OPTIONS_FILE")
    JSON_RPC_IGNORE_AVATARS=$(jq -r '.json_rpc_ignore_avatars // empty' "$OPTIONS_FILE")
    JSON_RPC_IGNORE_STICKERS=$(jq -r '.json_rpc_ignore_stickers // empty' "$OPTIONS_FILE")
    JSON_RPC_TRUST_NEW_IDENTITIES=$(jq -r '.json_rpc_trust_new_identities // empty' "$OPTIONS_FILE")
    DEFAULT_SIGNAL_TEXT_MODE=$(jq -r '.default_signal_text_mode // empty' "$OPTIONS_FILE")

    export MODE LOG_LEVEL

    # The container-internal port is fixed at 7583 so it matches the static
    # ports: declaration in config.yaml. The user changes the host-side port
    # via the addon's Network tab in Home Assistant.
    if [ "$EXPOSE_JSONRPC" = "true" ]; then
        export JSON_RPC_TCP_PORT=7583
    fi

    [ -n "$AUTO_RECEIVE_SCHEDULE" ] && export AUTO_RECEIVE_SCHEDULE
    [ -n "$JSON_RPC_IGNORE_ATTACHMENTS" ] && export JSON_RPC_IGNORE_ATTACHMENTS
    [ -n "$JSON_RPC_IGNORE_STORIES" ] && export JSON_RPC_IGNORE_STORIES
    [ -n "$JSON_RPC_IGNORE_AVATARS" ] && export JSON_RPC_IGNORE_AVATARS
    [ -n "$JSON_RPC_IGNORE_STICKERS" ] && export JSON_RPC_IGNORE_STICKERS
    [ -n "$JSON_RPC_TRUST_NEW_IDENTITIES" ] && export JSON_RPC_TRUST_NEW_IDENTITIES
    [ -n "$DEFAULT_SIGNAL_TEXT_MODE" ] && export DEFAULT_SIGNAL_TEXT_MODE
fi

mkdir -p "${SIGNAL_CLI_CONFIG_DIR:-/home/.local/share/signal-cli}"

exec /entrypoint.sh
