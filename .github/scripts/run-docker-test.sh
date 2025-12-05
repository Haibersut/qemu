#!/bin/bash
# Docker 容器内运行 QEMU 测试的入口脚本
# 此脚本在 Docker 容器内执行，用于安装依赖、配置环境并运行测试
#
# 用法: run-docker-test.sh
# 环境变量:
#   QEMU_VERSION - QEMU 版本号 (必需)
#   DISTRO - 发行版名称
#   DISTRO_VERSION - 发行版版本

set -e

WORKSPACE="${WORKSPACE:-/workspace}"

# ============================================================================
# 引入测试通用函数库
# ============================================================================
if [ -f "${WORKSPACE}/tests/test-common.sh" ]; then
    source "${WORKSPACE}/tests/test-common.sh"
else
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'
    log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
    log_pass() { echo -e "${GREEN}[PASS]${NC} $*"; }
    log_fail() { echo -e "${RED}[FAIL]${NC} $*"; }
    log_skip() { echo -e "${YELLOW}[SKIP]${NC} $*"; }
fi

# ============================================================================
# 参数验证
# ============================================================================
if [ -z "${QEMU_VERSION}" ]; then
    log_fail "QEMU_VERSION environment variable is required"
    exit 1
fi

QEMU_PREFIX="/usr/local/qemu-${QEMU_VERSION}"

log_info "Starting QEMU test in Docker container"
log_info "QEMU Version: ${QEMU_VERSION}"
log_info "Distro: ${DISTRO:-unknown} ${DISTRO_VERSION:-unknown}"
log_info "Architecture: $(uname -m)"
log_info "QEMU Prefix: ${QEMU_PREFIX}"

# ============================================================================
# 安装测试依赖
# ============================================================================
log_info "Installing test dependencies..."
if command -v dnf &> /dev/null; then
    dnf install -y findutils procps-ng which file || true
elif command -v yum &> /dev/null; then
    yum install -y findutils procps-ng which file || true
else
    log_skip "Unknown package manager, skipping dependency installation"
fi

# ============================================================================
# 查找并安装 RPM 包
# ============================================================================
log_info "Looking for pre-built RPM packages..."
RPM_FILE=$(find "${WORKSPACE}/artifacts" -name "qemu-*.rpm" -type f 2>/dev/null | head -1)

if [ -n "$RPM_FILE" ]; then
    log_info "Found RPM package: $RPM_FILE"
    log_info "Installing QEMU from RPM..."
    
    if command -v dnf &> /dev/null; then
        dnf install -y "$RPM_FILE" || rpm -ivh --nodeps "$RPM_FILE"
    else
        rpm -ivh --nodeps "$RPM_FILE"
    fi
    
    log_pass "QEMU installed from RPM"
else
    log_skip "No pre-built RPM found, building from source..."
    
    # 安装构建依赖
    if [ -x "${WORKSPACE}/scripts/install-deps.sh" ]; then
        log_info "Installing build dependencies..."
        "${WORKSPACE}/scripts/install-deps.sh"
    fi
    
    # 执行构建流程
    log_info "Downloading QEMU source..."
    [ -x "${WORKSPACE}/scripts/fetch.sh" ] && "${WORKSPACE}/scripts/fetch.sh"
    
    log_info "Extracting source..."
    [ -x "${WORKSPACE}/scripts/extract.sh" ] && "${WORKSPACE}/scripts/extract.sh"
    
    log_info "Configuring build..."
    [ -x "${WORKSPACE}/scripts/configure.sh" ] && "${WORKSPACE}/scripts/configure.sh"
    
    log_info "Building QEMU..."
    [ -x "${WORKSPACE}/scripts/build.sh" ] && "${WORKSPACE}/scripts/build.sh"
    
    log_info "Installing QEMU..."
    [ -x "${WORKSPACE}/scripts/install.sh" ] && "${WORKSPACE}/scripts/install.sh"
    
    log_pass "QEMU built and installed from source"
fi

# ============================================================================
# 验证 QEMU 安装
# ============================================================================
log_info "Verifying QEMU installation..."

NATIVE_ARCH=$(uname -m)
QEMU_BIN="${QEMU_PREFIX}/bin/qemu-system-${NATIVE_ARCH}"

if [ -x "${QEMU_BIN}" ]; then
    log_pass "QEMU binary found: ${QEMU_BIN}"
    "${QEMU_BIN}" --version
else
    log_skip "Native QEMU binary not found at: ${QEMU_BIN}"
    log_info "Available binaries in ${QEMU_PREFIX}/bin/:"
    ls -la "${QEMU_PREFIX}/bin/" 2>/dev/null || log_skip "bin directory not found"
fi

# 导出 QEMU_PREFIX 供测试使用
export QEMU_PREFIX

# ============================================================================
# 运行测试
# ============================================================================
log_info "Running QEMU tests..."

TEST_DIR="${WORKSPACE}/tests"
if [ ! -d "${TEST_DIR}" ]; then
    log_fail "Test directory not found: ${TEST_DIR}"
    exit 1
fi

cd "${TEST_DIR}"
chmod +x *.sh

# 运行所有测试
if [ -x "./run-all-tests.sh" ]; then
    ./run-all-tests.sh "${QEMU_PREFIX}"
    TEST_EXIT_CODE=$?
else
    log_fail "run-all-tests.sh not found"
    exit 1
fi

# ============================================================================
# 输出测试结果
# ============================================================================
if [ $TEST_EXIT_CODE -eq 0 ]; then
    log_pass "All tests passed!"
else
    log_fail "Some tests failed (exit code: $TEST_EXIT_CODE)"
fi

exit $TEST_EXIT_CODE
