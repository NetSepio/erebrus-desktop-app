#!/bin/sh

echo "[*] Before remove (<%= version %> : <%= pkg %> : $1)"

# When removing package: $1==0 for RPM; $1 == "remove" for DEB
_IS_REMOVE=0
if [ "$1" = "remove" -o "$1" = "0" ]; then
  _IS_REMOVE=1
fi

echo "[+] Trying to disconnect (before-remove) ..."
/usr/bin/erebrus disconnect || echo "[-] Failed to disconnect"

# Erasing Split Tunnel leftovers
# (we can not do it in 'after-remove' script, because it is executed after package/files removal)
echo "[+] Trying to erase Split Tunnel rules ..."
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

if [ $_IS_REMOVE = 1 ]; then
    echo "[+] Disabling firewall persistency (before-remove) ..."
    /usr/bin/erebrus firewall -persistent_off  

    echo "[+] Disabling firewall (before-remove) ..."
    /usr/bin/erebrus firewall -off || echo "[-] Failed to disable firewall"

    echo "[+] Logging out (before-remove) ..."
    /usr/bin/erebrus logout || echo "[-] Failed to log out"    
fi
