#!/bin/sh
set -e

# --- пользователи из users.conf ---
if [ -f /opt/rdp/users.conf ]; then
  while IFS=':' read -r login pass rest; do
    case "$login" in ''|\#*) continue ;; esac
    id "$login" >/dev/null 2>&1 || adduser -D -h "/home/$login" -s /bin/bash "$login"
    echo "$login:$pass" | chpasswd
  done < /opt/rdp/users.conf
else
  id rdpuser >/dev/null 2>&1 || adduser -D -h /home/rdpuser -s /bin/bash rdpuser
  echo "rdpuser:${RDP_PASSWORD:-changeme}" | chpasswd
fi

# --- структура профилей ---
mkdir -p /opt/rdp/profiles
chmod 755 /opt/rdp/profiles

# --- пользователи из users.conf ---
if [ -f /opt/rdp/users.conf ]; then
  while IFS=':' read -r login pass rest; do
    case "$login" in ''|\#*) continue ;; esac
    id "$login" >/dev/null 2>&1 || adduser -D -h "/home/$login" -s /bin/bash "$login"
    echo "$login:$pass" | chpasswd
    
    # создаём директорию профиля и symlink
    mkdir -p "/opt/rdp/profiles/$login"
    chown "$login:$login" "/opt/rdp/profiles/$login"
    
    # удаляем старый профиль если был в home (при первом запуске после миграции)
    [ -d "/home/$login/.ffprof" ] && rm -rf "/home/$login/.ffprof"
    
    # создаём symlink если нет
    [ ! -L "/home/$login/.ffprof" ] && ln -sf "/opt/rdp/profiles/$login" "/home/$login/.ffprof"
  done < /opt/rdp/users.conf
else
  id rdpuser >/dev/null 2>&1 || adduser -D -h /home/rdpuser -s /bin/bash rdpuser
  echo "rdpuser:${RDP_PASSWORD:-changeme}" | chpasswd
  mkdir -p /opt/rdp/profiles/rdpuser
  chown rdpuser:rdpuser /opt/rdp/profiles/rdpuser
  [ -d /home/rdpuser/.ffprof ] && rm -rf /home/rdpuser/.ffprof
  [ ! -L /home/rdpuser/.ffprof ] && ln -sf /opt/rdp/profiles/rdpuser /home/rdpuser/.ffprof
fi

mkdir -p /run/dbus /var/run/xrdp /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix
rm -f /run/dbus/dbus.pid /var/run/xrdp-sesman.pid /var/run/xrdp.pid /var/run/xrdp/*.pid /tmp/.X*-lock
rm -f /tmp/.X11-unix/X*
pkill -9 xrdp-sesman 2>/dev/null || true
pkill -9 xrdp 2>/dev/null || true

mount -o remount,size=1G /dev/shm 2>/dev/null || true

sed -i 's/^max_bpp=.*/max_bpp=16/' /etc/xrdp/xrdp.ini
grep -q '^tcp_nodelay' /etc/xrdp/xrdp.ini || echo 'tcp_nodelay=true' >> /etc/xrdp/xrdp.ini

# wrapper FF: свой профиль у каждого пользователя, один инстанс на пользователя
cat > /usr/local/bin/myff <<'FFEOF'
#!/bin/sh
H=$(awk -F: -v u="$(id -un)" '$1==u{print $6}' /etc/passwd)
pgrep -u "$(id -un)" -x firefox-esr >/dev/null && exit 0
firefox-esr -profile "$H/.ffprof" &
FFEOF
chmod +x /usr/local/bin/myff

cat > /etc/xdg/openbox/menu.xml <<'MENUEOF'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
<menu id="root-menu" label="Menu">
  <item label="Firefox"><action name="Execute"><command>myff</command></action></item>
  <item label="Xterm"><action name="Execute"><command>xterm</command></action></item>
  <item label="Завершить сессию"><action name="Exit"/></item>
</menu>
</openbox_menu>
MENUEOF

cat > /etc/xrdp/startwm.sh <<'WMEOF'
#!/bin/sh
U=$(id -un)
export XDG_RUNTIME_DIR=/tmp/runtime-$U
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
eval $(dbus-launch --sh-syntax)
export DBUS_SESSION_BUS_ADDRESS
export MOZ_DISABLE_CONTENT_SANDBOX=1

# дефолты сессии + пер-пользовательский конфиг
START_FF=yes; START_XTERM=yes; START_PANEL=yes
KB_LAYOUT="us,ru"; KB_OPTION="grp:alt_shift_toggle"
[ -f "/opt/rdp/session.d/$U.conf" ] && . "/opt/rdp/session.d/$U.conf"

PROF="$HOME/.ffprof"
mkdir -p "$PROF"
cat > "$PROF/user.js" <<'EOF'
user_pref("dom.ipc.processCount", 1);
user_pref("browser.sessionstore.interval", 60000);
user_pref("browser.sessionstore.max_tabs_undo", 0);
user_pref("browser.newtab.preload", false);
user_pref("browser.tabs.unloadOnMemoryLow", true);
user_pref("extensions.pocket.enabled", false);
user_pref("toolkit.telemetry.enabled", false);
user_pref("browser.cache.disk.enable", true);
user_pref("browser.cache.disk.capacity", 262144);
user_pref("browser.cache.memory.capacity", 32768);
EOF

if [ ! -f "$HOME/.xbindkeysrc" ]; then cat > "$HOME/.xbindkeysrc" <<'KBEOF'
"myff"
  control+alt + f
"xterm"
  control+alt + t
KBEOF
fi

openbox-session &
WMPID=$!
if [ "$START_PANEL" = yes ]; then tint2 & fi
if [ "$START_XTERM" = yes ]; then xterm -geometry 100x30 & fi
xbindkeys &
setxkbmap -layout "$KB_LAYOUT" -option "$KB_OPTION"
sleep 1
if [ "$START_FF" = yes ]; then myff; fi
wait $WMPID
WMEOF
chmod +x /etc/xrdp/startwm.sh

dbus-daemon --system --fork || true
/usr/sbin/xrdp-sesman --nodaemon >/var/log/sesman.log 2>&1 &
for i in $(seq 1 10); do
  netstat -tln | grep -q ':3350 ' && break
  sleep 1
done
if ! netstat -tln | grep -q ':3350 '; then
  echo "sesman failed:" >&2; cat /var/log/sesman.log >&2; exit 1
fi
exec /usr/sbin/xrdp --nodaemon
