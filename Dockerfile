FROM alpine:3.19

RUN apk add --no-cache \
    xrdp xorgxrdp xorg-server xf86-video-dummy xf86-input-libinput \
    openbox tint2 pcmanfm \
    firefox-esr filezilla putty \
    openssh-client sshfs \
    dbus-x11 xterm xbindkeys setxkbmap xkeyboard-config \
    ttf-dejavu terminus-font \
    bash shadow

RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# Скачиваем WinBox из Releases при сборке
RUN apk add --no-cache curl && \
    curl -L -o /usr/local/bin/winbox \
    "https://github.com/efkot-dev/mikrotik-rdp/releases/download/WinBox/WinBox"
RUN chmod +x /usr/local/bin/winbox

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
