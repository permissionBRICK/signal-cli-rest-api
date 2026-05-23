ARG BUILD_FROM=ghcr.io/permissionbrick/signal-cli-rest-api:latest
FROM ${BUILD_FROM}

# jq is needed to read /data/options.json that Home Assistant Supervisor
# generates from the user-facing addon options.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

# Persist signal-cli config across addon restarts/updates via /addon_config.
ENV SIGNAL_CLI_CONFIG_DIR=/addon_config/signal-cli

ENTRYPOINT ["/run.sh"]
