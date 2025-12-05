#!/bin/bash
# QEMU 测试通用函数库

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 测试计数器
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# 获取脚本目录
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# QEMU 版本（可通过环境变量覆盖）
QEMU_VERSION="${QEMU_VERSION:-9.0.1}"

# QEMU 安装路径（可通过环境变量覆盖）
# 与 configure.sh 中的路径保持一致: /usr/local/qemu-${QEMU_VERSION}
QEMU_PREFIX="${QEMU_PREFIX:-/usr/local/qemu-${QEMU_VERSION}}"

# 检测当前架构
CURRENT_ARCH=$(uname -m)
case "${CURRENT_ARCH}" in
    x86_64|amd64)
        CURRENT_ARCH="x86_64"
        QEMU_SYSTEM_BIN="qemu-system-x86_64"
        QEMU_USER_BIN="qemu-x86_64"
        ;;
    aarch64|arm64)
        CURRENT_ARCH="aarch64"
        QEMU_SYSTEM_BIN="qemu-system-aarch64"
        QEMU_USER_BIN="qemu-aarch64"
        ;;
    *)
        echo "Unsupported architecture: ${CURRENT_ARCH}"
        exit 1
        ;;
esac

# ============================================================================
# 日志函数
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $*"
}

log_skip() {
    echo -e "${YELLOW}[SKIP]${NC} $*"
}

log_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$*${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# ============================================================================
# 断言函数
# ============================================================================

# 断言相等
assert_equal() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Values should be equal}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ "$expected" = "$actual" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_pass "$message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_fail "$message"
        log_fail "  Expected: $expected"
        log_fail "  Actual:   $actual"
        return 1
    fi
}

# 断言不为空
assert_not_empty() {
    local value="$1"
    local message="${2:-Value should not be empty}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ -n "$value" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_pass "$message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_fail "$message"
        return 1
    fi
}

# 断言文件存在
assert_file_exists() {
    local file="$1"
    local message="${2:-File should exist: $file}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ -f "$file" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_pass "$message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_fail "$message"
        return 1
    fi
}

# 断言文件可执行
assert_file_executable() {
    local file="$1"
    local message="${2:-File should be executable: $file}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if [ -x "$file" ]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_pass "$message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_fail "$message"
        return 1
    fi
}

# 断言命令成功
assert_command_success() {
    local message="$1"
    shift
    local cmd="$@"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if eval "$cmd" > /dev/null 2>&1; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_pass "$message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_fail "$message"
        log_fail "  Command: $cmd"
        return 1
    fi
}

# 断言输出包含
assert_output_contains() {
    local expected="$1"
    local output="$2"
    local message="${3:-Output should contain: $expected}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if echo "$output" | grep -q -- "$expected"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_pass "$message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_fail "$message"
        log_fail "  Expected to contain: $expected"
        return 1
    fi
}

# 断言真
assert_true() {
    local condition="$1"
    local message="${2:-Condition should be true}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if eval "$condition"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_pass "$message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_fail "$message"
        return 1
    fi
}

# 跳过测试
skip_test() {
    local message="$1"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
    log_skip "$message"
}

# ============================================================================
# 辅助函数
# ============================================================================

# 获取 QEMU 二进制路径
get_qemu_bin() {
    local bin_name="$1"
    echo "${QEMU_PREFIX}/bin/${bin_name}"
}

# 获取 QEMU system 二进制路径（当前架构）
get_qemu_system() {
    get_qemu_bin "${QEMU_SYSTEM_BIN}"
}

# 获取 QEMU user 二进制路径（当前架构）
get_qemu_user() {
    get_qemu_bin "${QEMU_USER_BIN}"
}

# 运行 QEMU 命令并捕获输出
run_qemu() {
    local qemu_bin="$1"
    shift
    "$qemu_bin" "$@" 2>&1
}

# 运行带超时的命令
run_with_timeout() {
    local timeout_sec="$1"
    shift
    timeout "$timeout_sec" "$@" 2>&1 || true
}

# 检查 QEMU 是否支持某个设备
check_device_support() {
    local qemu_bin="$1"
    local device="$2"
    
    "$qemu_bin" -device help 2>&1 | grep -q -- "$device"
}

# 检查 QEMU 是否支持某个机器类型
check_machine_support() {
    local qemu_bin="$1"
    local machine="$2"
    
    "$qemu_bin" -machine help 2>&1 | grep -q -- "$machine"
}

# 检查 QEMU 是否支持某个 CPU 类型
check_cpu_support() {
    local qemu_bin="$1"
    local cpu="$2"
    
    "$qemu_bin" -cpu help 2>&1 | grep -q -- "$cpu"
}

# ============================================================================
# 测试报告
# ============================================================================

# 打印测试摘要
print_test_summary() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo -e "Total:   ${TESTS_TOTAL}"
    echo -e "Passed:  ${GREEN}${TESTS_PASSED}${NC}"
    echo -e "Failed:  ${RED}${TESTS_FAILED}${NC}"
    echo -e "Skipped: ${YELLOW}${TESTS_SKIPPED}${NC}"
    echo -e "${BLUE}============================================${NC}"
    
    if [ "$TESTS_FAILED" -gt 0 ]; then
        echo -e "${RED}Some tests failed!${NC}"
        return 1
    else
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    fi
}

# 导出测试结果为 JSON
export_results_json() {
    local output_file="${1:-test-results.json}"
    cat > "$output_file" << EOF
{
    "total": ${TESTS_TOTAL},
    "passed": ${TESTS_PASSED},
    "failed": ${TESTS_FAILED},
    "skipped": ${TESTS_SKIPPED},
    "success": $([ "$TESTS_FAILED" -eq 0 ] && echo "true" || echo "false"),
    "arch": "${CURRENT_ARCH}",
    "qemu_prefix": "${QEMU_PREFIX}",
    "timestamp": "$(date -Iseconds)"
}
EOF
    log_info "Test results exported to: $output_file"
}
