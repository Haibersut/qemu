#!/bin/bash
# 解压 QEMU 源码

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"

# 如果使用 git clone，则跳过解压
if [ -n "$QEMU_GIT_COMMIT" ]; then
    INFO "Using git source, skipping extract"
    exit 0
fi

INFO "Extracting QEMU source..."

WORKDIR "${SRC_DIR}"

tarball="$(basename "${QEMU_SRC_URL}")"

if [ ! -d "${QEMU_SRC_BASENAME}" ]; then
    INFO "Extracting ${tarball}..."
    RUN tar xf "${tarball}"
else
    INFO "Source directory already exists, skipping extraction"
fi

INFO "Extract completed successfully"
