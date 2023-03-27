########################################################################
## Ground Control
########################################################################

FROM ghcr.io/malyn/groundcontrol AS groundcontrol


########################################################################
## Tailscale
########################################################################

FROM tailscale/tailscale:v1.38.1 AS tailscale


########################################################################
## Final Image
########################################################################

FROM openresty/openresty:1.21.4.1-6-alpine-apk

# Copy binaries, scripts, and config.
WORKDIR /app

COPY --from=groundcontrol /groundcontrol ./
COPY --from=tailscale /usr/local/bin/tailscaled ./
COPY --from=tailscale /usr/local/bin/tailscale ./

COPY groundcontrol.toml ./
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Run Ground Control to monitor all of the processes.
ENTRYPOINT ["/app/groundcontrol", "/app/groundcontrol.toml"]