#!/bin/bash
# 安装构建依赖

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"
load_distro_config

INFO "Installing build dependencies..."

# 检查是否有发行版特定的安装函数
if type install_dependencies &>/dev/null; then
    install_dependencies
else
    ERROR "No install_dependencies function found for ${DISTRO}-${DISTRO_VERSION}"
    exit 1
fi

INFO "Dependencies installed successfully"
