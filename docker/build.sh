#!/bin/bash
# 本地 Docker 构建脚本
# 用于在本地测试构建

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# 默认配置
QEMU_VERSION="${QEMU_VERSION:-9.0.1}"
DISTRO="${DISTRO:-openeuler}"
DISTRO_VERSION="${DISTRO_VERSION:-24.03}"
ARCH="${ARCH:-$(uname -m)}"
PACKAGE_TYPE="${PACKAGE_TYPE:-rpm}"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --qemu-version)
            QEMU_VERSION="$2"
            shift 2
            ;;
        --distro)
            DISTRO="$2"
            shift 2
            ;;
        --distro-version)
            DISTRO_VERSION="$2"
            shift 2
            ;;
        --arch)
            ARCH="$2"
            shift 2
            ;;
        --package-type)
            PACKAGE_TYPE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --qemu-version VERSION   QEMU version to build (default: 9.0.1)"
            echo "  --distro DISTRO          Distribution name (default: openeuler)"
            echo "  --distro-version VERSION Distribution version (default: 24.03)"
            echo "  --arch ARCH              Target architecture (default: host arch)"
            echo "  --package-type TYPE      Package type: rpm or deb (default: rpm)"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

case "${DISTRO}-${DISTRO_VERSION}" in
    openeuler-22.03)
        BASE_IMAGE="openeuler/openeuler:22.03-lts-sp4"
        ;;
    openeuler-24.03)
        BASE_IMAGE="openeuler/openeuler:24.03-lts-sp2"
        ;;
    *)
        echo "Unknown distro: ${DISTRO}-${DISTRO_VERSION}"
        exit 1
        ;;
esac

# 构建标签
IMAGE_TAG="qemu-builder:${DISTRO}-${DISTRO_VERSION}-${ARCH}"
CONTAINER_NAME="qemu-build-${DISTRO}-${DISTRO_VERSION}-${ARCH}"

echo "=============================================="
echo "QEMU Docker Build"
echo "=============================================="
echo "QEMU Version: ${QEMU_VERSION}"
echo "Distribution: ${DISTRO}-${DISTRO_VERSION}"
echo "Architecture: ${ARCH}"
echo "Base Image: ${BASE_IMAGE}"
echo "Image Tag: ${IMAGE_TAG}"
echo "=============================================="

# 进入项目根目录
cd "${PROJECT_ROOT}"

# 确定平台参数
PLATFORM_ARG=""
if [ "${ARCH}" = "aarch64" ] || [ "${ARCH}" = "arm64" ]; then
    PLATFORM_ARG="--platform linux/arm64"
elif [ "${ARCH}" = "x86_64" ] || [ "${ARCH}" = "amd64" ]; then
    PLATFORM_ARG="--platform linux/amd64"
fi

# 构建 Docker 镜像
echo "Building Docker image..."
docker build ${PLATFORM_ARG} \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg QEMU_VERSION="${QEMU_VERSION}" \
    --build-arg DISTRO="${DISTRO}" \
    --build-arg DISTRO_VERSION="${DISTRO_VERSION}" \
    --build-arg PACKAGE_TYPE="${PACKAGE_TYPE}" \
    -t "${IMAGE_TAG}" \
    -f docker/Dockerfile \
    .

# 创建输出目录
OUTPUT_DIR="${PROJECT_ROOT}/output/${DISTRO}-${DISTRO_VERSION}/${ARCH}"
mkdir -p "${OUTPUT_DIR}"

# 运行构建
echo "Running build..."
docker run --rm ${PLATFORM_ARG} \
    --name "${CONTAINER_NAME}" \
    -v "${OUTPUT_DIR}:/workspace/output" \
    -e QEMU_VERSION="${QEMU_VERSION}" \
    -e DISTRO="${DISTRO}" \
    -e DISTRO_VERSION="${DISTRO_VERSION}" \
    -e PACKAGE_TYPE="${PACKAGE_TYPE}" \
    "${IMAGE_TAG}"

echo "=============================================="
echo "Build completed!"
echo "Output: ${OUTPUT_DIR}"
echo "=============================================="
ls -la "${OUTPUT_DIR}/"
