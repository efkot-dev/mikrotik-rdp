FROM alpine:latest

# Добавляем edge-репозитории для wine и winetricks
RUN echo "@edge-community https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "@edge-testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

RUN apk add --no-cache \
    # === X11 + RDP сервер ===
    xrdp xorgxrdp xorg-server \
    xf86-video-dummy xf86-input-libinput \
    openbox tint2 pcmanfm \
    \
    # === Приложения ===
    firefox-esr filezilla kitty \  # kitty: SSH-клиент + терминал (замена putty)
    \
    # === Сетевые утилиты ===
    openssh-client \
    \
    # === X11 компоненты ===
    dbus-x11 st \  # st (suckless terminal) вместо xterm — clipboard работает из коробки
    setxkbmap xkeyboard-config \
    \
    # === Шрифты ===
    ttf-dejavu terminus-font \
    \
    # === Система ===
    shadow \  # adduser/chpasswd/chsh
    \
    # === Wine ===
    wine@edge-community \  # Wine из edge
    winetricks@edge-testing \  # winetricks из edge/testing
    freerdp cabextract wget  # xfreerdp + распаковка CAB + wget

RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
