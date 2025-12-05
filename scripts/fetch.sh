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
    tarball="$(basename "${QEMU_SRC_URL}")"
    if [ ! -f "${tarball}" ]; then
        RUN wget -q "${QEMU_SRC_URL}" || {
            ERROR "Failed to download QEMU source"
            exit 1
        }
    else
        INFO "Source tarball already exists, skipping download"
    fi

    # MD5 校验
    if [ -n "${QEMU_SRC_MD5}" ]; then
        INFO "Verifying MD5 checksum..."
        actual_md5=$(md5sum "${tarball}" | awk '{print $1}')
        if [ "${actual_md5}" != "${QEMU_SRC_MD5}" ]; then
            ERROR "MD5 checksum verification failed!"
            ERROR "Expected: ${QEMU_SRC_MD5}"
            ERROR "Actual:   ${actual_md5}"
            exit 1
        fi
        INFO "MD5 checksum verified successfully"
    else
        WARN "No MD5 checksum provided, skipping verification"
    fi
fi

INFO "Fetch completed successfully"
