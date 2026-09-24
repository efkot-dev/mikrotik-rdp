#!/bin/sh
set -e

# Создаем пользователя если не существует
if ! id rdpuser >/dev/null 2>&1; then
    adduser -D -s /bin/sh rdpuser
fi

# Устанавливаем пароль
echo "rdpuser:${RDP_PASSWORD}" | chpasswd

# Создаем необходимые директории
mkdir -p /run/dbus /var/run/xrdp

# Запускаем dbus
dbus-daemon --system --fork

# Запускаем xrdp-sesman в фоне
/usr/sbin/xrdp-sesman

# Запускаем xrdp в foreground
exec /usr/sbin/xrdp --nodaemon
