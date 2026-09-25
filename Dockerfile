FROM alpine:3.19

# X + RDP + WM + браузер + обвес (панель, хоткеи, раскладки)
RUN apk add --no-cache \
    xrdp xorgxrdp xorg-server xf86-video-dummy xf86-input-libinput \
    openbox tint2 \
    firefox-esr \
    dbus-x11 xterm xbindkeys setxkbmap xkeyboard-config \
    ttf-dejavu terminus-font \
    bash shadow

# разрешаем X-сервер любому пользователю
RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# entrypoint из репозитория как fallback (на роутере его перебивает mount)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV RDP_PASSWORD=changeme
EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
