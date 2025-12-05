#!/bin/bash
# 从 GitHub Releases 下载 QEMU RPM 包
# 
# 用法: download-release.sh [OPTIONS]
#   --qemu-version VERSION     QEMU 版本号 (例如: 9.0.1)
#   --distro DISTRO            发行版名称 (例如: openeuler)
#   --distro-version VERSION   发行版版本 (例如: 22.03)
#   --arch ARCH                架构 (例如: x86_64, aarch64)
#   --release-tag TAG          Release 标签 (例如: v9.0.1-20251205-022153，留空使用最新)
#   --output-dir DIR           下载输出目录 (默认: artifacts)
#
# 环境变量:
#   GH_TOKEN - GitHub token 用于 API 访问
#   GITHUB_REPOSITORY - 仓库名称 (owner/repo)

set -e

# ============================================================================
# 颜色定义
# ============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_fail() { echo -e "${RED}[FAIL]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }

# ============================================================================
# 默认值
# ============================================================================
QEMU_VERSION=""
DISTRO=""
DISTRO_VERSION=""
ARCH=""
RELEASE_TAG=""
OUTPUT_DIR="artifacts"
REPO="${GITHUB_REPOSITORY:-Haibersut/qemu}"

# ============================================================================
# 参数解析
# ============================================================================
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
        --release-tag)
            RELEASE_TAG="$2"
            shift 2
            ;;
        --output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --repo)
            REPO="$2"
            shift 2
            ;;
        *)
            log_warn "Unknown option: $1"
            shift
            ;;
    esac
done

# ============================================================================
# 参数验证
# ============================================================================
if [ -z "$QEMU_VERSION" ]; then
    log_fail "QEMU version is required (--qemu-version)"
    exit 1
fi

if [ -z "$ARCH" ]; then
    ARCH=$(uname -m)
    log_info "Using detected architecture: $ARCH"
fi

# ============================================================================
# 构建 RPM 包名称模式
# ============================================================================
# RPM 命名格式: qemu-{version}-{distro_short}{distro_ver_short}-{timestamp}.{arch}.rpm
# 例如: qemu-9.0.1-oe2203-20251205022153.aarch64.rpm

# 获取发行版短名称
get_distro_short() {
    case "${DISTRO}" in
        openeuler|openEuler)
            echo "oe"
            ;;
        *)
            echo "${DISTRO:0:2}"
            ;;
    esac
}

# 获取版本短格式 (22.03 -> 2203)
get_version_short() {
    echo "${DISTRO_VERSION}" | tr -d '.'
}

DISTRO_SHORT=$(get_distro_short)
VERSION_SHORT=$(get_version_short)

# 构建 RPM 文件名模式
# 匹配格式: qemu-9.0.1-oe2203-*.aarch64.rpm
RPM_PATTERN="qemu-${QEMU_VERSION}-${DISTRO_SHORT}${VERSION_SHORT}-*.${ARCH}.rpm"

log_info "Looking for RPM matching pattern: ${RPM_PATTERN}"

# ============================================================================
# 创建输出目录
# ============================================================================
mkdir -p "${OUTPUT_DIR}"

# ============================================================================
# 获取 Release 信息
# ============================================================================
API_BASE="https://api.github.com/repos/${REPO}"

# 设置 curl 认证头
if [ -n "$GH_TOKEN" ]; then
    AUTH_HEADER="Authorization: token ${GH_TOKEN}"
else
    AUTH_HEADER=""
    log_warn "No GH_TOKEN set, API rate limits may apply"
fi

# 获取 release 信息
if [ -n "$RELEASE_TAG" ]; then
    log_info "Fetching specific release: ${RELEASE_TAG}"
    RELEASE_URL="${API_BASE}/releases/tags/${RELEASE_TAG}"
else
    log_info "Fetching latest release..."
    RELEASE_URL="${API_BASE}/releases/latest"
fi

# 使用 curl 获取 release 信息
if [ -n "$AUTH_HEADER" ]; then
    RELEASE_INFO=$(curl -sL -H "${AUTH_HEADER}" -H "Accept: application/vnd.github+json" "${RELEASE_URL}")
else
    RELEASE_INFO=$(curl -sL -H "Accept: application/vnd.github+json" "${RELEASE_URL}")
fi

# 检查是否获取到 release 信息
if echo "$RELEASE_INFO" | grep -q '"message".*"Not Found"'; then
    log_warn "Release not found, trying to list all releases..."
    
    # 列出所有 releases 并找到匹配的
    if [ -n "$AUTH_HEADER" ]; then
        ALL_RELEASES=$(curl -sL -H "${AUTH_HEADER}" -H "Accept: application/vnd.github+json" "${API_BASE}/releases")
    else
        ALL_RELEASES=$(curl -sL -H "Accept: application/vnd.github+json" "${API_BASE}/releases")
    fi
    
    # 查找包含 QEMU 版本的最新 release
    RELEASE_TAG=$(echo "$ALL_RELEASES" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    
    if [ -z "$RELEASE_TAG" ]; then
        log_fail "No releases found in repository"
        exit 1
    fi
    
    log_info "Found release tag: ${RELEASE_TAG}"
    RELEASE_URL="${API_BASE}/releases/tags/${RELEASE_TAG}"
    
    if [ -n "$AUTH_HEADER" ]; then
        RELEASE_INFO=$(curl -sL -H "${AUTH_HEADER}" -H "Accept: application/vnd.github+json" "${RELEASE_URL}")
    else
        RELEASE_INFO=$(curl -sL -H "Accept: application/vnd.github+json" "${RELEASE_URL}")
    fi
fi

# 提取 release tag
ACTUAL_TAG=$(echo "$RELEASE_INFO" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
log_info "Using release tag: ${ACTUAL_TAG}"

# ============================================================================
# 查找并下载匹配的 RPM 包
# ============================================================================
# 提取所有 asset 下载链接
ASSET_URLS=$(echo "$RELEASE_INFO" | grep -o '"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]*\.rpm"' | sed 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')

if [ -z "$ASSET_URLS" ]; then
    log_fail "No RPM assets found in release ${ACTUAL_TAG}"
    exit 1
fi

log_info "Found RPM assets in release:"
echo "$ASSET_URLS" | while read -r url; do
    echo "  - $(basename "$url")"
done

# 查找匹配的 RPM
DOWNLOAD_URL=""
while IFS= read -r url; do
    filename=$(basename "$url")
    # 检查是否匹配我们的模式
    if [[ "$filename" =~ ^qemu-${QEMU_VERSION}-${DISTRO_SHORT}${VERSION_SHORT}-.*\.${ARCH}\.rpm$ ]]; then
        DOWNLOAD_URL="$url"
        log_info "Found matching RPM: ${filename}"
        break
    fi
done <<< "$ASSET_URLS"

# 如果没有找到精确匹配，尝试更宽松的匹配
if [ -z "$DOWNLOAD_URL" ]; then
    log_warn "No exact match found, trying flexible matching..."
    while IFS= read -r url; do
        filename=$(basename "$url")
        # 宽松匹配: 包含 QEMU 版本和架构
        if [[ "$filename" =~ qemu.*${QEMU_VERSION}.*${ARCH}\.rpm$ ]]; then
            DOWNLOAD_URL="$url"
            log_info "Found matching RPM (flexible): ${filename}"
            break
        fi
    done <<< "$ASSET_URLS"
fi

if [ -z "$DOWNLOAD_URL" ]; then
    log_fail "No matching RPM found for pattern: ${RPM_PATTERN}"
    log_info "Available RPMs:"
    echo "$ASSET_URLS" | while read -r url; do
        echo "  - $(basename "$url")"
    done
    exit 1
fi

# ============================================================================
# 下载 RPM 包
# ============================================================================
RPM_FILENAME=$(basename "$DOWNLOAD_URL")
OUTPUT_PATH="${OUTPUT_DIR}/${RPM_FILENAME}"

log_info "Downloading: ${DOWNLOAD_URL}"
log_info "Saving to: ${OUTPUT_PATH}"

if [ -n "$AUTH_HEADER" ]; then
    curl -sL -H "${AUTH_HEADER}" -o "${OUTPUT_PATH}" "${DOWNLOAD_URL}"
else
    curl -sL -o "${OUTPUT_PATH}" "${DOWNLOAD_URL}"
fi

# 验证下载
if [ -f "${OUTPUT_PATH}" ] && [ -s "${OUTPUT_PATH}" ]; then
    FILE_SIZE=$(stat -f%z "${OUTPUT_PATH}" 2>/dev/null || stat -c%s "${OUTPUT_PATH}" 2>/dev/null || echo "unknown")
    log_pass "Successfully downloaded: ${RPM_FILENAME} (${FILE_SIZE} bytes)"
    
    # 验证 RPM 文件
    if command -v rpm &> /dev/null; then
        if rpm -qip "${OUTPUT_PATH}" &> /dev/null; then
            log_pass "RPM file is valid"
        else
            log_warn "Could not verify RPM file (this might be OK on non-RPM systems)"
        fi
    fi
else
    log_fail "Download failed or file is empty"
    exit 1
fi

# ============================================================================
# 输出结果
# ============================================================================
log_info "Download complete!"
log_info "RPM file: ${OUTPUT_PATH}"

# 导出环境变量供后续步骤使用
echo "RPM_FILE=${OUTPUT_PATH}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true
echo "RPM_FILENAME=${RPM_FILENAME}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true
echo "RELEASE_TAG=${ACTUAL_TAG}" >> "${GITHUB_ENV:-/dev/null}" 2>/dev/null || true

exit 0
