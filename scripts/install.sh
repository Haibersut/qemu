#!/bin/bash
# 安装 QEMU 到临时目录

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"

INFO "Installing QEMU..."

WORKDIR "${BUILD_DIR}/${QEMU_SRC_BASENAME}"

# 安装到 DESTDIR
export DESTDIR="${INSTALL_DIR}/${QEMU_ARTIFACT_BASENAME}"
mkdir -p "${DESTDIR}"

NPROC=$(get_nproc)
RUN make -j${NPROC} install DESTDIR="${DESTDIR}"

INFO "Install completed to: ${DESTDIR}"
