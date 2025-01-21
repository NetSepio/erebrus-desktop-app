//
//  Daemon for IVPN Client Desktop
//  https://github.com/ivpn/desktop-app
//
//  Created by Stelnykovych Alexandr.
//  Copyright (c) 2023 IVPN Limited.
//
//  This file is part of the Daemon for IVPN Client Desktop.
//
//  The Daemon for IVPN Client Desktop is free software: you can redistribute it and/or
//  modify it under the terms of the GNU General Public License as published by the Free
//  Software Foundation, either version 3 of the License, or (at your option) any later version.
//
//  The Daemon for IVPN Client Desktop is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
//  or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
//  details.
//
//  You should have received a copy of the GNU General Public License
//  along with the Daemon for IVPN Client Desktop. If not, see <https://www.gnu.org/licenses/>.
//

//go:build darwin
// +build darwin

package main

import (
	"fmt"
	"os"
	"path"

	"github.com/ivpn/desktop-app/daemon/shell"
)

// Prepare to start Erebrus daemon for macOS
func doPrepareToRun() error {
	// create symlink to 'erebrus' cli client
	binFolder := "/usr/local/bin"               // "/usr/local/bin"
	linkpath := path.Join(binFolder, "erebrus") // "/usr/local/bin/erebrus"
	if _, err := os.Stat(linkpath); os.IsNotExist(err) {
		// "/usr/local/bin"
		if _, err := os.Stat(binFolder); os.IsNotExist(err) {
			log.Info(fmt.Sprintf("Folder '%s' not exists. Creating it...", binFolder))
			if err = os.Mkdir(binFolder, 0775); err != nil {
				log.Error(fmt.Sprintf("Failed to create folder '%s': ", binFolder), err)
			}
		}
		// "/usr/local/bin/erebrus"
		log.Info("Creating symlink to Erebrus CLI: ", linkpath)
		err := shell.Exec(log, "/bin/ln", "-fs", "/Applications/Erebrus.app/Contents/MacOS/cli/erebrus", linkpath)
		if err != nil {
			log.Error("Failed to create symlink to Erebrus CLI: ", err)
		}
	}
	return nil
}

// inform OS-specific implementation about listener port
func doStartedOnPort(openedPort int, secret uint64) {
	implStartedOnPort(openedPort, secret)
}

// OS-specific service finalizer
func doStopped() {
	implStopped()
}

// checkIsAdmin - check is application running with root privileges
func doCheckIsAdmin() bool {
	uid := os.Geteuid()
	if uid != 0 {
		return false
	}

	return true
}
