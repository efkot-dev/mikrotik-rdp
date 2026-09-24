FROM alpine:3.19

RUN apk add --no-cache \
    xrdp xorg-server xf86-video-dummy xf86-input-void \
    openbox firefox-esr dbus-x11 xterm ttf-dejavu bash shadow

# Разрешаем запуск X-сервера любому пользователю
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Скрипт сессии (запускается после входа по RDP)
RUN printf '#!/bin/sh\nexport XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)\nmkdir -p $XDG_RUNTIME_DIR\nopenbox-session &\nfirefox-esr &\nwait' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Entrypoint: создает пользователя, стартует xrdp в foreground
RUN printf '#!/bin/sh\nadduser -D -s /bin/sh rdpuser 2>/dev/null || true\necho "rdpuser:${RDP_PASSWORD:-changeme}" | chpasswd\nmkdir -p /run/dbus /var/run/xrdp\ndbus-daemon --system --fork\n/usr/sbin/xrdp-sesman\nexec /usr/sbin/xrdp --nodaemon' > /entrypoint.sh && \
    chmod +x /entrypoint.sh

ENV RDP_PASSWORD=changeme
EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
