#!/bin/bash
# 生成构建矩阵
# 用于 GitHub Actions 动态生成构建任务

set -e

DISTROS="${1:-openeuler-22.03,openeuler-24.03}"
ARCHS="amd64 aarch64"

# 构建矩阵 JSON
MATRIX_INCLUDES="["
FIRST=true

IFS=',' read -ra DISTRO_ARRAY <<< "$DISTROS"
for distro_full in "${DISTRO_ARRAY[@]}"; do
    # 去除空格
    distro_full=$(echo "$distro_full" | xargs)
    
    # 分离发行版名称和版本
    distro=$(echo "$distro_full" | cut -d'-' -f1)
    distro_version=$(echo "$distro_full" | cut -d'-' -f2-)
    
    for arch in $ARCHS; do
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            MATRIX_INCLUDES+=","
        fi
        
        MATRIX_INCLUDES+="{\"distro\":\"${distro}\",\"distro_version\":\"${distro_version}\",\"arch\":\"${arch}\"}"
    done
done

MATRIX_INCLUDES+="]"

# 输出完整矩阵
MATRIX="{\"include\":${MATRIX_INCLUDES}}"

echo "Generated matrix: ${MATRIX}"

# 输出到 GitHub Actions
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "matrix=${MATRIX}" >> "$GITHUB_OUTPUT"
else
    echo "matrix=${MATRIX}"
fi
