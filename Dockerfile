FROM alpine:latest

# edge-репозитории: wine 11.x и winetricks
RUN echo "@edge-community https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
    echo "@edge-testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories

# Пакеты:
#   xrdp xorgxrdp xorg-server xf86-video-dummy xf86-input-libinput - RDP-сервер + X-бэкенд
#   openbox tint2 pcmanfm - WM, панель задач, файловый менеджер
#   firefox-esr filezilla kitty - браузер, SFTP/FTP, SSH-клиент/терминал
#   openssh-client - ssh/scp/sftp
#   dbus-x11 st - сессионный bus + терминал (clipboard из коробки)
#   setxkbmap xkeyboard-config - раскладки клавиатуры
#   ttf-dejavu terminus-font - шрифты (включая кириллицу)
#   shadow - adduser/chpasswd/chsh
#   wine winetricks - запуск Windows/.NET приложений
#   freerdp cabextract wget - RDP-клиент, распаковка CAB, загрузчик
RUN apk add --no-cache \
    xrdp xorgxrdp xorg-server \
    xf86-video-dummy xf86-input-libinput \
    openbox tint2 pcmanfm \
    firefox-esr filezilla kitty \
    openssh-client \
    dbus-x11 st sed\
    setxkbmap xkeyboard-config \
    ttf-dejavu terminus-font \
    shadow \
    wine@edge-community \
    winetricks@edge-testing \
    freerdp cabextract wget

RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
