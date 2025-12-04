#!/bin/bash
# 下载 QEMU 源码

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"

print_build_info

INFO "Fetching QEMU source..."

WORKDIR "${SRC_DIR}"

if [ -n "$QEMU_GIT_COMMIT" ]; then
    INFO "Cloning from git with commit: ${QEMU_GIT_COMMIT}"
    if [ ! -d "${QEMU_SRC_BASENAME}" ]; then
        RUN git clone --no-checkout https://github.com/qemu/qemu.git "${QEMU_SRC_BASENAME}"
        cd "${QEMU_SRC_BASENAME}"
        RUN git checkout "${QEMU_GIT_COMMIT}"
    else
        INFO "Source directory already exists, skipping clone"
    fi
else
    INFO "Downloading from: ${QEMU_SRC_URL}"
    local tarball="$(basename ${QEMU_SRC_URL})"
    if [ ! -f "${tarball}" ]; then
        RUN wget -q "${QEMU_SRC_URL}" || {
            WARN "Primary download failed, trying mirror..."
            RUN wget -q "https://mirrors.edge.kernel.org/pub/linux/kernel/people/agraf/qemu/${tarball}" || {
                ERROR "Failed to download QEMU source"
                exit 1
            }
        }
    else
        INFO "Source tarball already exists, skipping download"
    fi
fi

INFO "Fetch completed successfully"
