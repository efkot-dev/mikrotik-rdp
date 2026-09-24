FROM alpine:3.19

RUN apk add --no-cache \
    xrdp xorg-server xf86-video-dummy xf86-input-libinput \
    openbox firefox-esr dbus-x11 xterm ttf-dejavu bash shadow

# Разрешаем запуск X-сервера любому пользователю
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Скрипт сессии (запускается после входа по RDP)
RUN printf '#!/bin/sh\nexport XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)\nmkdir -p $XDG_RUNTIME_DIR\nopenbox-session &\nfirefox-esr &\nwait' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Entrypoint: создает пользователя, стартует xrdp в foreground
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV RDP_PASSWORD=changeme
EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
