# Signal CLI REST API (Home Assistant addon)

REST API wrapper around [signal-cli](https://github.com/AsamK/signal-cli), with
an optional direct JSON-RPC TCP socket exposed on a second port.

## Configuration options

| Option | Default | Description |
| --- | --- | --- |
| `mode` | `normal` | `normal`, `native`, `json-rpc`, or `json-rpc-native`. See the [upstream README](https://github.com/permissionBRICK/signal-cli-rest-api#execution-modes). |
| `log_level` | `info` | `debug`, `info`, `warn`, `error`. |
| `expose_jsonrpc` | `false` | Only meaningful in `json-rpc` / `json-rpc-native` modes. When `true`, the signal-cli daemon's JSON-RPC TCP socket is published on the addon's second port (container port `7583`). The host-side port can be changed in the addon's **Network** tab. |
| `auto_receive_schedule` | — | Cron expression for periodic `receive` (only in `normal`/`native` mode). |
| `json_rpc_ignore_attachments` | — | Skip attachment download (json-rpc only). |
| `json_rpc_ignore_stories` | — | Skip story download (json-rpc only). |
| `json_rpc_ignore_avatars` | — | Skip avatar download (json-rpc only). |
| `json_rpc_ignore_stickers` | — | Skip sticker download (json-rpc only). |
| `json_rpc_trust_new_identities` | — | `on-first-use`, `always`, or `never` (json-rpc only). |
| `default_signal_text_mode` | — | `normal` or `styled`. |

## Ports

| Container port | Default host port | What it is |
| --- | --- | --- |
| `8080/tcp` | `8080` | REST API. Always running. |
| `7583/tcp` | `7583` | Raw signal-cli JSON-RPC socket. Only listening when `mode` is `json-rpc*` and `expose_jsonrpc` is `true`. Change the host port in the addon's **Network** tab if 7583 is already used by something else on your HA host. |

## Persistence

Signal account state (keys, account database) is stored in
`/addon_config/signal-cli` inside the container, which Home Assistant persists
across addon updates.

## Registering a number

The REST API serves a QR code at `/v1/qrcodelink?device_name=<name>` that you
scan from the Signal mobile app to link the addon as a secondary device. See
the [upstream documentation](https://github.com/permissionBRICK/signal-cli-rest-api)
for full details.
