FROM --platform=linux/arm/v5 busybox:stable
COPY out/cloudflared /usr/bin/cloudflared
COPY start.sh /start.sh
ENTRYPOINT ["/bin/sh", "/start.sh"]
