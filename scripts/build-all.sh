#!/bin/bash
# 完整构建流程 - 从源码到二进制包
# 用于直接构建（非 RPM/DEB 方式）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"

print_build_info

# 加载发行版配置
load_distro_config

INFO "Starting full build process..."

# 安装依赖
INFO "Step 1: Installing dependencies..."
"${SCRIPT_DIR}/install-deps.sh"

# 下载源码
INFO "Step 2: Fetching source..."
"${SCRIPT_DIR}/fetch.sh"

# 解压
INFO "Step 3: Extracting source..."
"${SCRIPT_DIR}/extract.sh"

# 应用补丁
INFO "Step 4: Applying patches..."
"${SCRIPT_DIR}/patch.sh"

# 配置
INFO "Step 5: Configuring..."
"${SCRIPT_DIR}/configure.sh"

# 编译
INFO "Step 6: Building..."
"${SCRIPT_DIR}/build.sh"

# 安装
INFO "Step 7: Installing..."
"${SCRIPT_DIR}/install.sh"

INFO "=============================================="
INFO "Build completed successfully!"
INFO "Output: ${INSTALL_DIR}/${QEMU_ARTIFACT_BASENAME}"
INFO "=============================================="
