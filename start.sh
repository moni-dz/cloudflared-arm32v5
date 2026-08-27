#!/bin/sh

set -eu

if [ -n "${CONTAINER_GATEWAY:-}" ]; then
	ip route replace default via "$CONTAINER_GATEWAY"
fi

# $CLOUDFLARED_ARGS is intentionally unquoted so it word-splits into separate flags.
exec cloudflared tunnel --no-autoupdate run --token "${TUNNEL_TOKEN:?TUNNEL_TOKEN not set}" ${CLOUDFLARED_ARGS:-}
