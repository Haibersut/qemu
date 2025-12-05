#!/bin/bash
# 应用补丁到 QEMU 源码

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"

INFO "Applying patches to QEMU source..."

WORKDIR "${SRC_DIR}/${QEMU_SRC_BASENAME}"

PATCH_DIR="${WORK_ROOT}/patches"

if [ -d "${PATCH_DIR}" ] && [ "$(ls -A "${PATCH_DIR}"/*.patch 2>/dev/null)" ]; then
    for patchfile in "${PATCH_DIR}"/*.patch; do
        if [ -f "$patchfile" ]; then
            INFO "Applying patch: $(basename "$patchfile")"
            RUN patch -p1 -i "$patchfile" || {
                WARN "Patch $(basename "$patchfile") may have already been applied or failed"
            }
        fi
    done
else
    INFO "No patches found in ${PATCH_DIR}"
fi

INFO "Patch step completed"
