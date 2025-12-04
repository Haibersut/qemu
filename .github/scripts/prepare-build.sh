#!/bin/bash
# 准备构建环境
# 在 GitHub Actions 中运行，设置必要的环境

set -e

DISTRO="${1:-openeuler}"
DISTRO_VERSION="${2:-24.03}"

echo "=============================================="
echo "Preparing build environment"
echo "Distribution: ${DISTRO}-${DISTRO_VERSION}"
echo "=============================================="

# 确保输出目录存在
mkdir -p output

# 确保 patches 目录存在（即使为空）
mkdir -p patches

# 验证必要文件存在
if [ ! -f "docker/Dockerfile" ]; then
    echo "ERROR: docker/Dockerfile not found"
    exit 1
fi

if [ ! -f "distros/${DISTRO}-${DISTRO_VERSION}.sh" ]; then
    echo "ERROR: distros/${DISTRO}-${DISTRO_VERSION}.sh not found"
    exit 1
fi

if [ ! -f "specs/qemu-${DISTRO}.spec" ]; then
    echo "ERROR: specs/qemu-${DISTRO}.spec not found"
    exit 1
fi

echo "Build environment prepared successfully"
