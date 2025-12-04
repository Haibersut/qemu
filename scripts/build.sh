#!/bin/bash
# 编译 QEMU

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"

INFO "Building QEMU..."

WORKDIR "${BUILD_DIR}/${QEMU_SRC_BASENAME}"

NPROC=$(get_nproc)
INFO "Using ${NPROC} parallel jobs"

RUN make -j${NPROC}

INFO "Build completed successfully"
