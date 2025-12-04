#!/bin/bash
# 构建 RPM/DEB 包
# 在 GitHub Actions 中使用 Docker buildx 构建

set -e

# 解析参数
QEMU_VERSION="9.0.1"
DISTRO="openeuler"
DISTRO_VERSION="24.03"
ARCH="amd64"
PACKAGE_TYPE="rpm"

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
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "=============================================="
echo "Building QEMU Package"
echo "=============================================="
echo "QEMU Version: ${QEMU_VERSION}"
echo "Distribution: ${DISTRO}-${DISTRO_VERSION}"
echo "Architecture: ${ARCH}"
echo "Package Type: ${PACKAGE_TYPE}"
echo "=============================================="

# 确定基础镜像
case "${DISTRO}-${DISTRO_VERSION}" in
    openeuler-22.03)
        BASE_IMAGE="openeuler/openeuler:22.03-lts"
        ;;
    openeuler-24.03)
        BASE_IMAGE="openeuler/openeuler:24.03-lts"
        ;;
    *)
        echo "ERROR: Unknown distro: ${DISTRO}-${DISTRO_VERSION}"
        exit 1
        ;;
esac

# 确定平台
case "${ARCH}" in
    amd64|x86_64)
        PLATFORM="linux/amd64"
        ARCH_NORMALIZED="x86_64"
        ;;
    aarch64|arm64)
        PLATFORM="linux/arm64"
        ARCH_NORMALIZED="aarch64"
        ;;
    *)
        echo "ERROR: Unknown architecture: ${ARCH}"
        exit 1
        ;;
esac

# 构建标签
IMAGE_TAG="qemu-builder:${DISTRO}-${DISTRO_VERSION}-${ARCH_NORMALIZED}"
CONTAINER_NAME="qemu-build-$$"

# 输出目录
OUTPUT_DIR="output/${DISTRO}-${DISTRO_VERSION}/${ARCH_NORMALIZED}"
mkdir -p "${OUTPUT_DIR}"

echo "Base Image: ${BASE_IMAGE}"
echo "Platform: ${PLATFORM}"
echo "Image Tag: ${IMAGE_TAG}"
echo "Output Directory: ${OUTPUT_DIR}"

# 构建 Docker 镜像
echo ""
echo "Building Docker image..."

if [ "${PLATFORM}" != "linux/amd64" ]; then
    echo "Cross-architecture build detected, verifying QEMU setup..."
    if [ -f /proc/sys/fs/binfmt_misc/qemu-aarch64 ]; then
        echo "QEMU aarch64 handler registered:"
        cat /proc/sys/fs/binfmt_misc/qemu-aarch64 || true
    fi
fi

docker buildx build \
    --platform "${PLATFORM}" \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg QEMU_VERSION="${QEMU_VERSION}" \
    --build-arg DISTRO="${DISTRO}" \
    --build-arg DISTRO_VERSION="${DISTRO_VERSION}" \
    --build-arg PACKAGE_TYPE="${PACKAGE_TYPE}" \
    --load \
    -t "${IMAGE_TAG}" \
    -f docker/Dockerfile \
    .

# 运行构建
echo ""
echo "Running build in container..."
docker run --rm \
    --platform "${PLATFORM}" \
    --name "${CONTAINER_NAME}" \
    -v "$(pwd)/${OUTPUT_DIR}:/workspace/output" \
    -e QEMU_VERSION="${QEMU_VERSION}" \
    -e DISTRO="${DISTRO}" \
    -e DISTRO_VERSION="${DISTRO_VERSION}" \
    -e PACKAGE_TYPE="${PACKAGE_TYPE}" \
    "${IMAGE_TAG}"

# 验证输出
echo ""
echo "=============================================="
echo "Build completed!"
echo "=============================================="
echo "Output files:"
ls -la "${OUTPUT_DIR}/"

# 计算文件数量
FILE_COUNT=$(find "${OUTPUT_DIR}" -name "*.rpm" -o -name "*.deb" 2>/dev/null | wc -l)
if [ "$FILE_COUNT" -eq 0 ]; then
    echo "WARNING: No package files found in output!"
    exit 1
fi

echo ""
echo "Build successful: ${FILE_COUNT} package(s) created"
