#!/bin/bash
# 生成 QEMU 测试矩阵
# 用于 GitHub Actions 测试工作流
#
# 用法: generate-test-matrix.sh [distros]
# 参数:
#   distros - 逗号分隔的发行版列表 (默认: openeuler-22.03,openeuler-24.03)
#
# 输出: 设置 GITHUB_OUTPUT 中的 matrix 变量

set -e

# 默认发行版
DEFAULT_DISTROS="openeuler-22.03,openeuler-24.03"
DISTROS="${1:-$DEFAULT_DISTROS}"

echo "Generating test matrix for distros: ${DISTROS}"

# Docker 镜像映射
get_docker_image() {
    local distro="$1"
    local version="$2"
    
    case "${distro}-${version}" in
        openeuler-22.03)
            echo "openeuler/openeuler:22.03-lts-sp4"
            ;;
        openeuler-24.03)
            echo "openeuler/openeuler:24.03-lts-sp2"
            ;;
        *)
            echo "openeuler/openeuler:${version}"
            ;;
    esac
}

# Runner 映射
get_runner() {
    local arch="$1"
    
    case "${arch}" in
        x86_64|amd64)
            echo "ubuntu-latest"
            ;;
        aarch64|arm64)
            echo "ubuntu-24.04-arm"
            ;;
        *)
            echo "ubuntu-latest"
            ;;
    esac
}

# 初始化矩阵 JSON
MATRIX_JSON='{"include":['
FIRST=true

# 解析发行版列表
IFS=',' read -ra DISTRO_LIST <<< "$DISTROS"

for distro_spec in "${DISTRO_LIST[@]}"; do
    # 去除空格
    distro_spec=$(echo "$distro_spec" | xargs)
    
    # 解析发行版和版本 (格式: distro-version)
    if [[ "$distro_spec" =~ ^([a-zA-Z]+)-(.+)$ ]]; then
        DISTRO="${BASH_REMATCH[1]}"
        VERSION="${BASH_REMATCH[2]}"
    else
        echo "Warning: Invalid distro spec: $distro_spec, skipping..."
        continue
    fi
    
    # 为每个架构生成条目
    for ARCH in "x86_64" "aarch64"; do
        RUNNER=$(get_runner "$ARCH")
        DOCKER_IMAGE=$(get_docker_image "$DISTRO" "$VERSION")
        
        # 添加逗号分隔符
        if [ "$FIRST" = true ]; then
            FIRST=false
        else
            MATRIX_JSON+=','
        fi
        
        # 添加矩阵条目
        MATRIX_JSON+=$(cat <<EOF
{
  "distro": "${DISTRO}",
  "distro_version": "${VERSION}",
  "arch": "${ARCH}",
  "runner": "${RUNNER}",
  "docker_image": "${DOCKER_IMAGE}"
}
EOF
)
    done
done

MATRIX_JSON+=']}'

# 输出到 GITHUB_OUTPUT
if [ -n "${GITHUB_OUTPUT}" ]; then
    echo "matrix=$(echo "${MATRIX_JSON}" | jq -c)" >> "$GITHUB_OUTPUT"
fi

# 打印格式化的矩阵
echo "Generated matrix:"
echo "${MATRIX_JSON}" | jq .
