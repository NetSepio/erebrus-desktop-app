#!/bin/sh

echo "[*] Before install (<%= version %> : <%= pkg %> : $1)"

# Skip installation if 'erebrus' snap pachage already installed
snap list erebrus > /dev/null 2>&1 && echo "[!] INSTALLATION CANCELED: The snap package 'erebrus' is already installed. Please, uninstall the 'erebrus' snap package first." && exit 1

EREBRUS_BIN="/usr/bin/erebrus"
if [ ! -f ${EREBRUS_BIN} ] && [ -f /usr/local/bin/erebrus ]; then
  # old installation path (used till v3.3.20)
  EREBRUS_BIN="/usr/local/bin/erebrus"
  echo "[ ] Detected old installation path: '$EREBRUS_BIN'"
fi

if [ -f ${EREBRUS_BIN} ]; then
  #echo "[+] Trying to disable firewall (before install)..."
  #${EREBRUS_BIN} firewall -off || echo "[-] Failed to disable firewall"

  echo "[+] Trying to disconnect (before install) ..."
  ${EREBRUS_BIN} disconnect || echo "[-] Failed to disconnect"
fi

# Erasing Split Tunnel leftovers from old installation
# Required for: 
# - RPM upgrade
# - compatibility with old package versions (v3.12.0 and older)
if [ -f /opt/erebrus/etc/firewall.sh ] || [ -f /opt/erebrus/etc/splittun.sh ]; then 
  echo "[+] Trying to erase old Split Tunnel rules ..."
  if [ -f /opt/erebrus/etc/firewall.sh ]; then
    printf "    * /opt/erebrus/etc/firewall.sh -only_dns_off: "
    /opt/erebrus/etc/firewall.sh -only_dns_off >/dev/null 2>&1 && echo "OK" || echo "NOK"
  fi
  if [ -f /opt/erebrus/etc/splittun.sh ]; then
    printf "    * /opt/erebrus/etc/splittun.sh reset        : "
    /opt/erebrus/etc/splittun.sh reset >/dev/null 2>&1         && echo "OK" || echo "NOK"
    printf "    * /opt/erebrus/etc/splittun.sh stop         : "
    /opt/erebrus/etc/splittun.sh stop >/dev/null 2>&1          && echo "OK" || echo "NOK"
  fi
fi

# ########################################################################################
#
# Next lines is in use only for compatibility with old package versions (v3.10.10 and older)
#
# ########################################################################################
# Folders changed:
# "/opt/erebrus/mutable" -> "/etc/opt/erebrus/mutable" 
# "/opt/erebrus/log"     -> "/var/log/erebrus" 
if [ -d /opt/erebrus/mutable ]; then 
  echo "[+] Migrating old-style mutable data from the previous installation ..."
  mkdir -p /etc/opt/erebrus
  mv /opt/erebrus/mutable /etc/opt/erebrus/mutable
fi
if [ -d /opt/erebrus/log ]; then 
  echo "[+] Migrating old-style logs from the previous installation ..." 
  mv /opt/erebrus/log /var/log/erebrus
fi

# ########################################################################################
#
# Next lines is in use only for compatibility with old package versions (v3.8.20 and older)
#
# ########################################################################################

# DEB: 'before-remove' script (old versions) saving account credentials into 'upgradeID.tmp' and doing logout,
# here we have to rename it to 'toUpgradeID.tmp' (to be compatible with old installation script style)
if [ -f /opt/erebrus/mutable/upgradeID.tmp ]; then
    echo "[ ] Upgrade detected (before-install: old-style)"
    mv /opt/erebrus/mutable/upgradeID.tmp /opt/erebrus/mutable/toUpgradeID.tmp || echo "[-] Failed to prepare accountID to re-login"
fi

# RPM: in order to sckip 'before-remove.sh \ after-remove.sh' scripts from the old-style installer
# we have to create file '/opt/erebrus/mutable/rpm_upgrade.lock'
if [ "<%= pkg %>" = "rpm" ]; then
  if [ -f ${EREBRUS_BIN} ]; then
    mkdir -p /opt/erebrus/mutable
    echo "upgrade" > /opt/erebrus/mutable/rpm_upgrade.lock || echo "[-] Failed to save rpm_upgrade.lock"
  fi
fi
