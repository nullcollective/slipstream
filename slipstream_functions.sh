#!/usr/bin/env bash

# slipstream functions
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

USB_DISK="" # LEAVE BLANK
TARGET_DISK="" # LEAVE BLANK
HEADER="∙∙∙∙∙·▫▫ᵒᴼᵒ▫ₒₒ▫ᵒᴼᵒ▫ₒₒ▫ᵒᴼᵒ☼)===>"

function init {
    mkdir -p "${TARGET_MOUNT}" 2>/dev/null
    mkdir -p "${USB_MOUNT}" 2>/dev/null
    # VERIFY PATHS
    for dir in $TARGET_MOUNT $USB_MOUNT;do
	    if [[ ! -d "${dir}" ]]; then
		    echo "DIRECTORY CREATION ISSUES" ; exit 1
	    fi
    done
    echo "[>] MOUNT PATHS CHECK PASSED"
}

function list_payloads {
    echo "AVAILABLE PAYLOADS"
    echo "-------------------------------------------"
    for payload in $(compgen -A function); do
	    if [[ "${payload}" == *"payload_"* ]]; then
  		    echo "[-->] ${payload}"
	    fi
    done
}

function drive_detection_target {
    # DETECT WINDOWS PARTITION
    for disk in $(lsblk -dn -o NAME,TYPE | awk '$2 == "disk" { print "/dev/" $1 }');do
	    part=$(parted -m "${disk}" print | grep -i 'ntfs.*Basic data partition' | cut -d: -f1)
	    if [[ -n "$part" ]]; then
		    TARGET_DISK=$(echo "$disk"p"$part")
		    break
	    fi
    done
    if [[ -z "${TARGET_DISK}" ]]; then echo "NO Win10/11 TARGET DRIVE CANDIDATES FOUND" ; exit 1 ; fi
}

function drive_detection_usb {
    # DETECT USB DATA PARTITION
    local usbpart=$(lsblk -m -o name,label --raw | awk -v label="$USB_LABEL" '$2 == label { print "/dev/" $1 }')
    if [[ -n "${usbpart}" ]]; then USB_DISK=${usbpart} ; fi
    if [[ -z "${USB_DISK}" ]]; then echo "NO USB DATA PARTITION FOUND" ; exit 1 ; fi
}

function drive_mounting_target {
    mount -o ro ${TARGET_DISK} ${TARGET_MOUNT} || { exit 1; }
}
function drive_mounting_target_rw {
    mount -o rw ${TARGET_DISK} ${TARGET_MOUNT} || { exit 1; }
}

function drive_mounting_usb {
    mount -o sync,noatime,nodiratime ${USB_DISK} ${USB_MOUNT} || { exit 1; }
}

function drive_unmounting_target {
    umount ${TARGET_MOUNT} ; echo "[>>>] TARGET DRIVE UNMOUNTED"
}

function drive_unmounting_usb {
    umount ${USB_MOUNT} ; echo "[>>>] USB UNMOUNTED"
}

# Function to display script usage
function usage {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo " -h      Display this help message"
    echo " -l      List Available Payloads"
    echo " -x      Runs Script with Specified Payload"
}

function cmd_prompt {
    #$OPTARG
    case $opt in
    h)
        usage;;
    l)
        list_payloads;;
    x)
        selected_payload="${OPTARG}"
        if [[ "$selected_payload" == payload_* ]];then
            function="${selected_payload#payload_}"
            if declare -f "$function" > /dev/null;then
                echo "RUNNING PAYLOAD: ${function} ${HEADER}"
                "$function"
            else
                echo "INVALID PAYLOAD";exit 1
            fi
        else
            echo "PAYLOAD NOT FOUND";exit 1
        fi;;
    *)
        echo "Invalid option: $1" >&2
        usage;exit 1;;
    esac
}

function cleanup {
    echo "cleanup"
}