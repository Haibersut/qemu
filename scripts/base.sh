#!/bin/bash
# QEMU 构建基础配置脚本
# 包含通用变量和辅助函数

set -e

# 版本配置
QEMU_NAME="qemu"
QEMU_VERSION="${QEMU_VERSION:-9.0.1}"

# 可选：使用 git commit 而不是 tarball
QEMU_GIT_COMMIT="${QEMU_GIT_COMMIT:-}"

# 构建序列号（版本更新后重置为空或从1开始）
QEMU_BUILD_SERIAL="${QEMU_BUILD_SERIAL:-1}"

# 目录配置
WORK_ROOT="${WORK_ROOT:-$(pwd)}"
SRC_DIR="${WORK_ROOT}/src"
BUILD_DIR="${WORK_ROOT}/build"
INSTALL_DIR="${WORK_ROOT}/install"
OUTPUT_DIR="${WORK_ROOT}/output"

# 主机信息
HOST_OS_RAW=$(uname -s)
HOST_ARCH_RAW=$(uname -m)
HOST_OS=${HOST_OS_RAW,,}
HOST_ARCH=${HOST_ARCH_RAW,,}

# 发行版信息
DISTRO="${DISTRO:-openeuler}"
DISTRO_VERSION="${DISTRO_VERSION:-24.03}"

# 包类型 (rpm 或 deb)
PACKAGE_TYPE="${PACKAGE_TYPE:-rpm}"

# 源码相关
if [ -n "$QEMU_GIT_COMMIT" ]; then
    QEMU_SRC_BASENAME="${QEMU_NAME}-${QEMU_VERSION}-${QEMU_GIT_COMMIT}"
else
    QEMU_SRC_BASENAME="${QEMU_NAME}-${QEMU_VERSION}"
    QEMU_SRC_URL="https://download.qemu.org/${QEMU_SRC_BASENAME}.tar.xz"
fi

# 构建产物名称
QEMU_ARTIFACT_F0=${QEMU_GIT_COMMIT:+-$QEMU_GIT_COMMIT}
QEMU_ARTIFACT_F1=${QEMU_BUILD_SERIAL:+.$QEMU_BUILD_SERIAL}
QEMU_ARTIFACT_BASENAME="${QEMU_NAME}-${HOST_OS}-${HOST_ARCH}-${QEMU_VERSION}${QEMU_ARTIFACT_F0}${QEMU_ARTIFACT_F1}"

# =============================================================================
# 辅助函数
# =============================================================================

# 创建并进入目录
WORKDIR() {
    local dir="$1"
    mkdir -p "$dir"
    cd "$dir"
    echo "[WORKDIR] $(pwd)"
}

# 执行命令并打印
RUN() {
    echo "[RUN] $*"
    "$@"
}

# 打印信息
INFO() {
    echo "[INFO] $*"
}

# 打印错误
ERROR() {
    echo "[ERROR] $*" >&2
}

# 打印警告
WARN() {
    echo "[WARN] $*"
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        ERROR "Command '$1' not found"
        return 1
    fi
}

# 获取包管理器
get_package_manager() {
    if command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v yum &> /dev/null; then
        echo "yum"
    elif command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v apk &> /dev/null; then
        echo "apk"
    else
        ERROR "No supported package manager found"
        return 1
    fi
}

# 获取 CPU 核心数
get_nproc() {
    nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4
}

# 加载发行版配置
load_distro_config() {
    local distro_config="${WORK_ROOT}/distros/${DISTRO}-${DISTRO_VERSION}.sh"
    if [ -f "$distro_config" ]; then
        INFO "Loading distro config: $distro_config"
        source "$distro_config"
    else
        WARN "Distro config not found: $distro_config, using defaults"
    fi
}

# 打印构建信息
print_build_info() {
    INFO "=============================================="
    INFO "QEMU Build Configuration"
    INFO "=============================================="
    INFO "QEMU Version: ${QEMU_VERSION}"
    INFO "Host OS: ${HOST_OS}"
    INFO "Host Arch: ${HOST_ARCH}"
    INFO "Distro: ${DISTRO}-${DISTRO_VERSION}"
    INFO "Package Type: ${PACKAGE_TYPE}"
    INFO "Work Root: ${WORK_ROOT}"
    INFO "=============================================="
}

# 导出变量供子脚本使用
export QEMU_NAME QEMU_VERSION QEMU_GIT_COMMIT QEMU_BUILD_SERIAL
export WORK_ROOT SRC_DIR BUILD_DIR INSTALL_DIR OUTPUT_DIR
export HOST_OS HOST_ARCH DISTRO DISTRO_VERSION PACKAGE_TYPE
export QEMU_SRC_BASENAME QEMU_SRC_URL QEMU_ARTIFACT_BASENAME
