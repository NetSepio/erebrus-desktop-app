#!/bin/sh

echo "[*] After remove (<%= version %> : <%= pkg %> : $1)"

# Obtaining information about user running the script
# (script can be executed with 'sudo', but we should get real user)
USER="${SUDO_USER:-$USER}"

# When removing package: $1==0 for RPM; $1 == "remove" for DEB
_IS_REMOVE=0
if [ "$1" = "remove" -o "$1" = "0" ]; then
  _IS_REMOVE=1
fi

# ########################################################################################
#
# COMPATIBILITY BLOCK (BEGIN)
#
# Next block is in use only for compatibility with old package versions (v3.8.20 and older)
#
# ########################################################################################
# RPM: do not forget to remove file '/opt/erebrus/mutable/rpm_upgrade.lock' (if exists)
if [ "<%= pkg %>" = "rpm" ]; then
    if [ -f /opt/erebrus/mutable/rpm_upgrade.lock ]; then
        rm /opt/erebrus/mutable/rpm_upgrade.lock || echo "[-] Failed to remove rpm_upgrade.lock"
    fi
fi
# ########################################################################################
# COMPATIBILITY BLOCK (END)
# ########################################################################################

if [ $_IS_REMOVE = 0 ]; then
  echo "[ ] Upgrade detected. After-remove operations skipped"
  exit 0
fi

silent() {
  "$@" > /dev/null 2>&1
}

has_systemd() {
  # Some OS vendors put systemd in ... different places ...
  [ -d "/lib/systemd/system/" -o -d "/usr/lib/systemd/system" ] && silent command -v systemctl
}

try_systemd_stop() {
    if has_systemd ; then
        echo "[ ] systemd detected. Trying to stop service ..."

        echo "[+] Stopping service"
        silent systemctl stop erebrus-service

        echo "[+] Disabling service"
        silent systemctl disable erebrus-service

        if [ -f "/etc/systemd/system/erebrus-service.service" ]; then
            echo "[+] Removing service"
            rm /etc/systemd/system/erebrus-service.service
        fi
        if [ -f "/usr/lib/systemd/system/erebrus-service.service" ]; then
            echo "[+] Removing service"
            rm /usr/lib/systemd/system/erebrus-service.service
        fi
    fi
}

uninstall_bash_completion() {
    # get bash completion folder (according to https://github.com/scop/bash-completion)
    bash_competion_folder=$(pkg-config --variable=completionsdir bash-completion 2>&1) 
    if [ $? -eq 0 ] && [ ! -z $bash_competion_folder ] ; then
      completion_file=${bash_competion_folder}/erebrus
      if [ -f ${completion_file} ] ; then
        echo "[+] Uninstalling bash completion ('${completion_file}')"
        rm "${completion_file}"    
      fi
    fi
}

# stop & disable service
try_systemd_stop

uninstall_bash_completion

PLEASERUN_DIR="/usr/share/pleaserun/erebrus-service"
if [ -d $PLEASERUN_DIR ] ; then
  echo "[+] Service cleanup (pleaserun) ..."
  silent sh $PLEASERUN_DIR/cleanup.sh 
  rm -fr $PLEASERUN_DIR
fi 

#EREBRUS_DIR="/opt/erebrus"
#if [ -d $EREBRUS_DIR ] ; then
#  echo "[+] Removing other files ..."
#  # Normally, all files which were installed, deleted automatically.
#  # But erebrus-service also writing to 'mutable' additional temporary files (uninstaller know nothing about them).
#  # Therefore, we are completely removing all content of '/opt/erebrus/mutable'.
#  # Also, there could stay empty dirs which were not deleted automatically.
#  rm -rf $EREBRUS_DIR || echo "[-] Removing '$EREBRUS_DIR' folder failed"
#fi

echo "[+] Removing mutable data ..."
EREBRUS_TMP="/etc/opt/erebrus"
rm -rf $EREBRUS_TMP

echo "[+] Removing logs ..."
EREBRUS_LOG="/var/log/erebrus" 
rm -rf $EREBRUS_LOG


