#!/bin/sh

echo "[*] After install (<%= version %> : <%= pkg %> : $1)"

NEED_TO_SAVE_INSTRUCTIONS=true
EREBRUS_OPT="/opt/erebrus"
EREBRUS_ETC="/opt/erebrus/etc"
EREBRUS_TMP="/etc/opt/erebrus/mutable"
EREBRUS_LOG="/var/log/erebrus"

SERVERS_FILE_BUNDLED="$EREBRUS_ETC/servers.json"
SERVERS_FILE_DEST="$EREBRUS_TMP/servers.json"

mkdir -p $EREBRUS_LOG
mkdir -p $EREBRUS_TMP

INSTRUCTIONS_FILE="$EREBRUS_TMP/service_install.txt"
[ -e $INSTRUCTIONS_FILE ] && rm $INSTRUCTIONS_FILE

silent() {
  "$@" > /dev/null 2>&1
}

has_systemd() {
  # Some OS vendors put systemd in ... different places ...
  [ -d "/lib/systemd/system/" -o -d "/usr/lib/systemd/system" ] && silent command -v systemctl
}

try_systemd_install() {
    if has_systemd ; then
        echo "[ ] systemd detected. Trying to start service ..."
        echo "[+] Stopping old service (if exists)"
        systemctl stop erebrus-service
        echo "[+] Enabling service"
        systemctl enable erebrus-service || return 1
        echo "[+] Starting service"
        systemctl start erebrus-service || return 1

        NEED_TO_SAVE_INSTRUCTIONS=false
        return 0
    else
        echo "[-] Unable to start service automatically"
    fi
}

install_bash_completion() {
    # get bash completion folder (according to https://github.com/scop/bash-completion)
    bash_competion_folder=$(pkg-config --variable=completionsdir bash-completion 2>&1) 
    if [ $? -eq 0 ] && [ ! -z $bash_competion_folder ] ; then
      completion_file=${bash_competion_folder}/erebrus
      echo "[+] Installing bash completion (into '${completion_file}')"
      silent cp "$EREBRUS_ETC/erebrus.bash-completion" "${completion_file}"
      silent chmod 644 "${completion_file}"
    else
      echo "[ ] Installing bash completion - SKIPPED"
    fi
}

echo "[+] Defining access rights for files ..."
silent chmod 0400 $EREBRUS_ETC/*             # can read only owner (root)
silent chmod 0600 $EREBRUS_ETC/servers.json  # can read/wrire only owner (root)
silent chmod 0700 $EREBRUS_ETC/*.sh          # can execute only owner (root)
silent chmod 0700 $EREBRUS_ETC/*.up          # can execute only owner (root)
silent chmod 0700 $EREBRUS_ETC/*.down        # can execute only owner (root)
silent chmod 0755 /usr/bin/erebrus           # can change only owner (root)
silent chmod 0755 /usr/bin/erebrus-service   # can change only owner (root)
silent chmod 0755 $EREBRUS_OPT/obfsproxy/obfs4proxy          # can change only owner (root)
silent chmod 0755 $EREBRUS_OPT/v2ray/v2ray                   # can change only owner (root)
silent chmod 0755 $EREBRUS_OPT/wireguard-tools/wg-quick      # can change only owner (root)
silent chmod 0755 $EREBRUS_OPT/wireguard-tools/wg            # can change only owner (root)
silent chmod 0755 $EREBRUS_OPT/dnscrypt-proxy/dnscrypt-proxy # can change only owner (root)
silent chmod 0755 $EREBRUS_OPT/kem/kem-helper                # can change only owner (root)

if [ -f "${SERVERS_FILE_BUNDLED}" ] && [ -f "${SERVERS_FILE_DEST}" ]; then 
  # New service version may use new format of 'servers.json'. 
  # We must be sure that new format is in use.
  echo "[+] Overwriting servers information by the data from the bundle ..."
  silent cp "${SERVERS_FILE_BUNDLED}" "${SERVERS_FILE_DEST}"  
fi

echo "[+] Service install start (pleaserun) ..."
INSTALL_OUTPUT=$(sh /usr/share/pleaserun/erebrus-service/install.sh)
if [ $? -eq 0 ]; then
    # Print output of the install script
    echo $INSTALL_OUTPUT
    try_systemd_install
else
    # Print output of the install script
    echo $INSTALL_OUTPUT
    echo "[-] Service install FAILED!"
fi

if $NEED_TO_SAVE_INSTRUCTIONS == true ; then
    echo $INSTALL_OUTPUT > $INSTRUCTIONS_FILE
    echo "[!] Service start instructions saved into file: '$INSTRUCTIONS_FILE'"
fi

install_bash_completion

# ########################################################################################
#
# Next lines is in use only for compatibility with old package versions (v3.8.20 and older)
#
# DEB: 'before-remove' script (old versions) saving account credentials into 'toUpgradeID.tmp' and doing logout,
# here we have to re-login
#
# ########################################################################################
FILE_ACCID_TO_UPGRADE="/opt/erebrus/mutable/toUpgradeID.tmp"
if [ -f $FILE_ACCID_TO_UPGRADE ]; then
  echo "[ ] Upgrade detected (after-install: old-style)"
  # It is an upgrade.
  # We need to re-login after installation finished.
  # Read account ID
  ACCID=$(cat $FILE_ACCID_TO_UPGRADE) || echo "[-] Finishing installation: Failed to read accountID to re-login"

  # do not forget to remove temporary file
  silent rm $FILE_ACCID_TO_UPGRADE

  echo "[+] Disabling firewall (after-install: old-style) ..."
  /usr/bin/erebrus firewall -off || echo "[-] Failed to disable firewall"

  if [ ! -z "$ACCID" ]; then
    # giving a chance for a daemon to fully start
    sleep 1
    echo "[+] Logging in (after-install: old-style) ..."
    /usr/bin/erebrus login $ACCID #||  echo "[-] Finishing installation: Failed to to re-login (try#1)"
    if [ ! $? -eq 0 ]; then
      echo "[-] Finishing installation: Failed to to re-login (try#1)"
      echo "[ ] Retry ..."
      sleep 3
      /usr/bin/erebrus login $ACCID ||  echo "[-] Finishing installation: Failed to to re-login (try#2)"
    fi
  fi
fi
