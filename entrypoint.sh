#!/bin/sh
set -e

# Создаем пользователя
if ! id rdpuser >/dev/null 2>&1; then
    adduser -D -s /bin/sh rdpuser
fi

# Устанавливаем пароль
echo "rdpuser:${RDP_PASSWORD}" | chpasswd

# Создаем необходимые директории
mkdir -p /run/dbus /var/run/xrdp /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Запускаем dbus
dbus-daemon --system --fork

# Запускаем xrdp-sesman
/usr/sbin/xrdp-sesman &

# Ждем запуска sesman
sleep 2

# Запускаем xrdp в foreground
exec /usr/sbin/xrdp --nodaemon
