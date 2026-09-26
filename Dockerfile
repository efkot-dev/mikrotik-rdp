FROM alpine:3.19

RUN apk add --no-cache \
    xrdp xorgxrdp xorg-server xf86-video-dummy xf86-input-libinput \
    openbox tint2 pcmanfm \
    firefox-esr filezilla putty \
    openssh-client sshfs \
    dbus-x11 xterm xbindkeys setxkbmap xkeyboard-config \
    ttf-dejavu terminus-font \
    bash shadow wine wine-mono winetricks freerdp cabextract wget

RUN wget -O /usr/local/bin/winetricks https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks && \
    chmod +x /usr/local/bin/winetricks

RUN echo "allowed_users=anybody" > /etc/X11/Xwrapper.config

# xterm с Ctrl+C/V и нормальным clipboard
RUN mkdir -p /etc/skel && \
    echo 'xterm*metaSendsEscape: true' > /etc/skel/.Xresources && \
    echo 'xterm*selectToClipboard: true' >> /etc/skel/.Xresources && \
    echo 'xterm*VT100.Translations: #override \\' >> /etc/skel/.Xresources && \
    echo '  Ctrl <Key>C: copy-selection(CLIPBOARD) \\' >> /etc/skel/.Xresources && \
    echo '  Ctrl <Key>V: insert-selection(CLIPBOARD)' >> /etc/skel/.Xresources

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3389
ENTRYPOINT ["/entrypoint.sh"]
