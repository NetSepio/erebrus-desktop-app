#!/bin/sh
sudo launchctl unload /Library/LaunchDaemons/net.erebrus.client.Helper.plist
sudo rm /Library/LaunchDaemons/net.erebrus.client.Helper.plist
sudo rm /Library/PrivilegedHelperTools/net.erebrus.client.Helper
