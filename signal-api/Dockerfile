ARG BUILD_FROM=ghcr.io/permissionbrick/signal-cli-rest-api:latest
FROM ${BUILD_FROM}

# jq is needed to read /data/options.json that Home Assistant Supervisor
# generates from the user-facing addon options.
RUN apt-get update \
    && apt-get install -y --no-install-recommends jq \
    && rm -rf /var/lib/apt/lists/*

COPY run.sh /run.sh
RUN chmod +x /run.sh

# signal-cli's config dir is set via the addon's `environment:` block in
# config.yaml (HA-native way). We declare /config as a VOLUME so docker
# persists it as a named volume across addon restarts.
VOLUME ["/config"]

ENTRYPOINT ["/run.sh"]
