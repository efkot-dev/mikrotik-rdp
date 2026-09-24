FROM alpine:3.19

# Установка пакетов
RUN apk add --no-cache \
    xrdp xorg-server xf86-video-dummy xf86-input-libinput \
    openbox firefox-esr dbus-x11 xterm ttf-dejavu bash shadow \
    xorgxrdp

# Разрешаем запуск X-сервера любому пользователю
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Настройка xrdp - слушаем все интерфейсы
RUN sed -i 's/^port=3389/port=3389/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^max_bpp=32/max_bpp=24/' /etc/xrdp/xrdp.ini && \
    echo "tcp_keepalive=true" >> /etc/xrdp/xrdp.ini

# Настройка Xorg для работы в headless режиме
RUN printf 'Section "Device"\n    Identifier "DummyDevice"\n    Driver "dummy"\n    Option "ConstantDPI" "true"\n    VideoRam 128000\nEndSection\n\nSection "Monitor"\n    Identifier "DummyMonitor"\n    HorizSync 28.0-80.0\n    VertRefresh 48.0-75.0\n    ModeLine "1920x1080" 148.50 1920 2008 2052 2200 1080 1084 1089 1125 +hsync +vsync\nEndSection\n\nSection "Screen"\n    Identifier "DummyScreen"\n    Device "DummyDevice"\n    Monitor "DummyMonitor"\n    DefaultDepth 24\n    SubSection "Display"\n        Depth 24\n        Modes "1920x1080"\n    EndSubSection\nEndSection' > /etc/X11/xorg.conf

# Скрипт сессии
RUN printf '#!/bin/sh\nexport XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)\nmkdir -p $XDG_RUNTIME_DIR\nchmod 700 $XDG_RUNTIME_DIR\nopenbox-session &\nsleep 2\nfirefox-esr &\nwait' > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startsm.sh

# Entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV RDP_PASSWORD=changeme
ENV DISPLAY=:10
EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
