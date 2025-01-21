//
//  UI for IVPN Client Desktop
//  https://github.com/ivpn/desktop-app
//
//  Created by Stelnykovych Alexandr.
//  Copyright (c) 2023 IVPN Limited.
//
//  This file is part of the UI for IVPN Client Desktop.
//
//  The UI for IVPN Client Desktop is free software: you can redistribute it and/or
//  modify it under the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  The UI for IVPN Client Desktop is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
//  details.
//
//  You should have received a copy of the GNU General Public License
//  along with the UI for IVPN Client Desktop. If not, see <https://www.gnu.org/licenses/>.
//

import { Platform, PlatformEnum } from "@/platform/platform";
import wifiHelperMacOS from "@/os-helpers/macos/wifi-helper.js";

function InstallDaemon(onInstallationStarted, done) {
  // Re-install agent every time when daemon is installed to ensure that it's up-to-date
  // Here we just uninstall it. It will be installed later automatically
  try {
    wifiHelperMacOS.UninstallAgent();
  } catch (e) {
    console.log(e);
  }

  let spawn = require("child_process").spawn;

  let logStringPrefix = "[Erebrus Installer --install_helper]";

  try {
    let cmd = spawn(
      "/Applications/Erebrus.app/Contents/MacOS/Erebrus Installer.app/Contents/MacOS/Erebrus Installer",
      ["--install_helper"]
    );

    if (onInstallationStarted != null) onInstallationStarted();

    cmd.stdout.on("data", (data) => {
      console.log(`${logStringPrefix}: ${data}`);
    });
    cmd.stderr.on("data", (err) => {
      console.log(`[ERROR] ${logStringPrefix}: ${err}`);
    });

    cmd.on("error", (err) => {
      console.error(err);
      if (done) done(-1);
    });

    cmd.on("exit", (code) => {
      if (done) done(code);
    });
  } catch (e) {
    console.log(`Failed to run ${logStringPrefix}: ${e}`);
  }
}

function TryStartDaemon(done) {
  let spawn = require("child_process").spawn;

  let logStringPrefix = "[Erebrus Installer --start_helper]";

  try {
    let cmd = spawn(
      "/Applications/Erebrus.app/Contents/MacOS/Erebrus Installer.app/Contents/MacOS/Erebrus Installer",
      ["--start_helper"]
    );

    cmd.stderr.on("data", (err) => {
      console.log(`[ERROR] ${logStringPrefix}: ${err}`);
    });

    cmd.on("error", (err) => {
      console.error(err);
      if (done) done(-1);
    });

    cmd.on("exit", (code) => {
      if (done) done(code);
    });
  } catch (e) {
    console.log(`Failed to run ${logStringPrefix}: ${e}`);
  }
}

// result: onResultFunc(exitCode), where exitCode==0 when daemon have to be installed
function IsDaemonInstallationRequired(onResultFunc) {
  if (Platform() !== PlatformEnum.macOS) {
    if (onResultFunc) onResultFunc(1);
    return;
  }

  let logStringPrefix = "[Erebrus Installer --is_helper_installation_required]";

  let spawn = require("child_process").spawn;
  try {
    let cmd = spawn(
      "/Applications/Erebrus.app/Contents/MacOS/Erebrus Installer.app/Contents/MacOS/Erebrus Installer",
      ["--is_helper_installation_required"]
    );

    cmd.on("error", (err) => {
      console.error(err);
      if (onResultFunc) onResultFunc(-1);
    });

    cmd.on("exit", (code) => {
      // if exitCode == 0 - the daemon must be installed
      if (onResultFunc) onResultFunc(code);
    });
  } catch (e) {
    console.log(`Failed to run ${logStringPrefix}: ${e}`);
    if (onResultFunc) onResultFunc(-1);
  }
}

function InstallDaemonIfRequired(onInstallationStarted, done) {
  if (Platform() !== PlatformEnum.macOS) return;

  try {
    IsDaemonInstallationRequired((code) => {
      // if exitCode == 0 - the daemon must be installed
      if (code == 0) InstallDaemon(onInstallationStarted, done);
      else if (done) done(code);
    });
  } catch (e) {
    console.log(
      `Failed to run [[IVPN Installer --is_helper_installation_required]]: ${e}`
    );
    if (done) done(-1);
  }
}

export default {
  InstallDaemonIfRequired,
  IsDaemonInstallationRequired,
  TryStartDaemon,
};
