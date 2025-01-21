#!/bin/bash

#save current dir
_BASE_DIR="$( pwd )"
_SCRIPT=`basename "$0"`
#enter the script folder
cd "$(dirname "$0")"
_SCRIPT_DIR="$( pwd )"

# check result of last executed command
function CheckLastResult
{
  if ! [ $? -eq 0 ]; then #check result of last command
    if [ -n "$1" ]; then
      echo $1
    else
      echo "FAILED"
    fi
    exit 1
  fi
}

# The Apple DevID certificate which will be used to sign Erebrus Agent (Daemon) binary
# The helper will check Erebrus Agent signature with this value
_SIGN_CERT="" # E.g. "WXXXXXXXXN". Specific value can be passed by command-line argument: -c <APPLE_DEVID_SERT>
while getopts ":c:" opt; do
  case $opt in
    c) _SIGN_CERT="$OPTARG"
    ;;
  esac
done

if [ -z "${_SIGN_CERT}" ]; then
  echo "Usage:"
  echo "    $0 -c <APPLE_DEVID_CERTIFICATE>"
  echo "    Example: $0 -c WXXXXXXXXN"
  exit 1
fi

if [ ! -f "../helper/net.erebrus.client.Helper" ]; then
  echo " File not exists '../helper/net.erebrus.client.Helper'. Please, compile helper project first."
  exit 1
fi

rm -fr bin
CheckLastResult

echo "[ ] *** Compiling Erebrus Installer / Uninstaller ***"

echo "[+] Erebrus Installer: updating certificate info in .plist ..."
# echo "    Apple DevID certificate: '${_SIGN_CERT}'"
plutil -replace SMPrivilegedExecutables -xml \
        "<dict> \
      		<key>net.erebrus.client.Helper</key> \
      		<string>identifier net.erebrus.client.Helper and certificate leaf[subject.OU] = ${_SIGN_CERT}</string> \
      	</dict>" "Erebrus Installer-Info.plist" || CheckLastResult
plutil -replace SMPrivilegedExecutables -xml \
        "<dict> \
          <key>net.erebrus.client.Helper</key> \
          <string>identifier net.erebrus.client.Helper and certificate leaf[subject.OU] = ${_SIGN_CERT}</string> \
        </dict>" "Erebrus Uninstaller-Info.plist" || CheckLastResult

echo "[+] Erebrus Installer: make ..."
make
CheckLastResult

echo "[+] Erebrus Installer: Erebrus Installer.app ..."
mkdir -p "bin/Erebrus Installer.app/Contents/Library/LaunchServices" || CheckLastResult
mkdir -p "bin/Erebrus Installer.app/Contents/MacOS" || CheckLastResult
cp "../helper/net.erebrus.client.Helper" "bin/Erebrus Installer.app/Contents/Library/LaunchServices" || CheckLastResult
cp "bin/Erebrus Installer" "bin/Erebrus Installer.app/Contents/MacOS" || CheckLastResult
cp "etc/install.sh" "bin/Erebrus Installer.app/Contents/MacOS" || CheckLastResult
cp "Erebrus Installer-Info.plist" "bin/Erebrus Installer.app/Contents/Info.plist" || CheckLastResult

echo "[+] Erebrus Installer: Erebrus Uninstaller.app ..."
mkdir -p "bin/Erebrus Uninstaller.app/Contents/MacOS" || CheckLastResult
cp "bin/Erebrus Uninstaller" "bin/Erebrus Uninstaller.app/Contents/MacOS" || CheckLastResult
cp "Erebrus Uninstaller-Info.plist" "bin/Erebrus Uninstaller.app/Contents/Info.plist" || CheckLastResult

echo "[ ] Erebrus Installer: Done"
echo "    ${_SCRIPT_DIR}/bin/Erebrus Installer.app"
echo "    ${_SCRIPT_DIR}/bin/Erebrus Uninstaller.app"

cd ${_BASE_DIR}
