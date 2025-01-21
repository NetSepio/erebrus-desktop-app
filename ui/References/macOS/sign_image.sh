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

# The Apple DevID certificate which will be used to sign binaries
_SIGN_CERT=""
# reading version info from arguments
while getopts ":c:" opt; do
  case $opt in
    c) _SIGN_CERT="$OPTARG"
    ;;
  esac
done

if [ -z "${_SIGN_CERT}" ]; then
  echo "ERROR: Apple DevID not defined"
  echo "Usage:"
  echo "    $0 -c <APPLE_DEVID_SERT> [-libivpn]"
  exit 1
fi

if [ ! -d "_image/Erebrus.app" ]; then
  echo "ERROR: folder not exists '_image/Erebrus.app'!"
fi

echo "[i] Signing by cert: '${_SIGN_CERT}'"

# temporarily setting the IFS (internal field seperator) to the newline character.
# (required to process result pf 'find' command)
IFS=$'\n'; set -f

echo "[+] Signing obfsproxy libraries..."
for f in $(find '_image/Erebrus.app/Contents/Resources/obfsproxy' -name '*.so');
do
  echo "    signing: [" $f "]";
  codesign --verbose=4 --force --sign "${_SIGN_CERT}" "$f"
  CheckLastResult "Signing failed"
done

#restore temporarily setting the IFS (internal field seperator)
unset IFS; set +f

ListCompiledLibs=()
if [[ "$@" == *"-libivpn"* ]]
then
  ListCompiledLibs=(
  "_image/Erebrus.app/Contents/MacOS/libivpn.dylib"
  )
fi

ListCompiledBinaries=(
"_image/Erebrus.app/Contents/MacOS/Erebrus"
"_image/Erebrus.app/Contents/MacOS/Erebrus Agent"
"_image/Erebrus.app/Contents/MacOS/cli/erebrus"
"_image/Erebrus.app/Contents/MacOS/kem/kem-helper"
"_image/Erebrus.app/Contents/MacOS/Erebrus Installer.app/Contents/MacOS/Erebrus Installer"
"_image/Erebrus.app/Contents/MacOS/Erebrus Installer.app"
"_image/Erebrus.app"
"_image/Erebrus Uninstaller.app"
"_image/Erebrus Uninstaller.app/Contents/MacOS/Erebrus Uninstaller"
)

ListThirdPartyBinaries=(
"_image/Erebrus.app/Contents/MacOS/Erebrus Installer.app/Contents/Library/LaunchServices/net.erebrus.client.Helper"
"_image/Erebrus.app/Contents/MacOS/net.erebrus.LaunchAgent"
# "_image/Erebrus.app/Contents/MacOS/openvpn"
"_image/Erebrus.app/Contents/MacOS/WireGuard/wg"
"_image/Erebrus.app/Contents/MacOS/WireGuard/wireguard-go"
"_image/Erebrus.app/Contents/Resources/obfsproxy/obfs4proxy"
"_image/Erebrus.app/Contents/MacOS/v2ray/v2ray"
"_image/Erebrus.app/Contents/MacOS/dnscrypt-proxy/dnscrypt-proxy"
)

echo "[+] Signing compiled libs..."
for f in "${ListCompiledLibs[@]}";
do
  echo "    signing: [" $f "]";
  codesign --verbose=4 --force --sign "${_SIGN_CERT}" "$f"
  CheckLastResult "Signing failed"
done

echo "[+] Signing third-party binaries..."
for f in "${ListThirdPartyBinaries[@]}";
do
  echo "    signing: [" $f "]";
  codesign --verbose=4 --force --sign "${_SIGN_CERT}" --options runtime "$f"
  CheckLastResult "Signing failed"
done

echo "[+] Signing compiled binaries..."
for f in "${ListCompiledBinaries[@]}";
do
  echo "    signing: [" $f "]";
  codesign --verbose=4 --force --sign "${_SIGN_CERT}" --options runtime "$f" --deep --entitlements build_HarderingEntitlements.plist
  CheckLastResult "Signing failed"
done
