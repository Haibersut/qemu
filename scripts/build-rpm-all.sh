#!/bin/bash
# 完整构建流程 - 构建 RPM 包
# 这是 Docker 容器内运行的入口脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"

print_build_info

# 加载发行版配置
load_distro_config

INFO "Starting RPM build process..."

# 安装依赖
INFO "Step 1: Installing dependencies..."
"${SCRIPT_DIR}/install-deps.sh"

# 构建 RPM
INFO "Step 2: Building RPM..."
"${SCRIPT_DIR}/build-rpm.sh"

INFO "=============================================="
INFO "RPM build completed successfully!"
INFO "Output: ${OUTPUT_DIR}"
INFO "=============================================="

ls -la "${OUTPUT_DIR}/"
