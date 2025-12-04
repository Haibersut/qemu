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
BUILD_DATE=""
BUILD_TIME=""

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
        --build-date)
            BUILD_DATE="$2"
            shift 2
            ;;
        --build-time)
            BUILD_TIME="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# 如果没有传入构建日期时间，则使用当前时间
if [ -z "$BUILD_DATE" ]; then
    BUILD_DATE=$(date +'%Y%m%d')
fi
if [ -z "$BUILD_TIME" ]; then
    BUILD_TIME=$(date +'%H%M%S')
fi

# 生成发行版缩写
get_distro_abbr() {
    local distro="$1"
    local version="$2"
    case "${distro}" in
        openeuler)
            local ver_short=$(echo "$version" | tr -d '.')
            echo "oe${ver_short}"
            ;;
        centos)
            echo "el${version}"
            ;;
        fedora)
            echo "fc${version}"
            ;;
        ubuntu)
            echo "ubuntu${version}"
            ;;
        debian)
            echo "deb${version}"
            ;;
        *)
            echo "${distro}${version}"
            ;;
    esac
}

DISTRO_ABBR=$(get_distro_abbr "$DISTRO" "$DISTRO_VERSION")

echo "=============================================="
echo "Building QEMU Package"
echo "=============================================="
echo "QEMU Version: ${QEMU_VERSION}"
echo "Distribution: ${DISTRO}-${DISTRO_VERSION}"
echo "Distro Abbr:  ${DISTRO_ABBR}"
echo "Architecture: ${ARCH}"
echo "Package Type: ${PACKAGE_TYPE}"
echo "Build Date:   ${BUILD_DATE}"
echo "Build Time:   ${BUILD_TIME}"
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
    -e DISTRO_ABBR="${DISTRO_ABBR}" \
    -e BUILD_DATE="${BUILD_DATE}" \
    -e BUILD_TIME="${BUILD_TIME}" \
    -e PACKAGE_TYPE="${PACKAGE_TYPE}" \
    "${IMAGE_TAG}"

# 重命名 RPM 包为规范格式
# 格式: qemu-<版本>-<发行版缩写>-<日期><时间>.<架构>.rpm
echo ""
echo "Renaming packages to standard format..."
for rpm in "${OUTPUT_DIR}"/*.rpm; do
    if [ -f "$rpm" ]; then
        filename=$(basename "$rpm")
        # 提取架构信息 (x86_64, aarch64, noarch, src)
        if [[ "$filename" =~ \.(x86_64|aarch64|noarch|src)\.rpm$ ]]; then
            pkg_arch="${BASH_REMATCH[1]}"
        else
            pkg_arch="${ARCH_NORMALIZED}"
        fi
        
        new_name="qemu-${QEMU_VERSION}-${DISTRO_ABBR}-${BUILD_DATE}${BUILD_TIME}.${pkg_arch}.rpm"
        
        if [ "$filename" != "$new_name" ]; then
            echo "Renaming: $filename -> $new_name"
            mv "$rpm" "${OUTPUT_DIR}/${new_name}"
        fi
    fi
done

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
