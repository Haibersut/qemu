#!/bin/bash
# 运行所有 QEMU 测试
# 用法: ./run-all-tests.sh [QEMU_PREFIX]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test-common.sh"

# 允许从命令行参数覆盖 QEMU_PREFIX
if [ -n "$1" ]; then
    export QEMU_PREFIX="$1"
fi

log_header "QEMU Test Suite"
log_info "QEMU Prefix: ${QEMU_PREFIX}"
log_info "Architecture: ${CURRENT_ARCH}"
log_info "Test Directory: ${SCRIPT_DIR}"

# 验证 QEMU 安装
if [ ! -d "${QEMU_PREFIX}" ]; then
    log_fail "QEMU installation not found at: ${QEMU_PREFIX}"
    exit 1
fi

if [ ! -d "${QEMU_PREFIX}/bin" ]; then
    log_fail "QEMU bin directory not found: ${QEMU_PREFIX}/bin"
    exit 1
fi

# 测试脚本列表
TEST_SCRIPTS=(
    "test-basic.sh"
    "test-features.sh"
    "test-quick-boot.sh"
    "test-cross-arch.sh"
)

# 全局测试统计
GLOBAL_TOTAL=0
GLOBAL_PASSED=0
GLOBAL_FAILED=0
GLOBAL_SKIPPED=0
FAILED_TESTS=()

# 运行每个测试脚本
for test_script in "${TEST_SCRIPTS[@]}"; do
    test_path="${SCRIPT_DIR}/${test_script}"
    
    if [ ! -f "$test_path" ]; then
        log_skip "Test script not found: $test_script"
        continue
    fi
    
    echo ""
    echo -e "${BLUE}################################################################${NC}"
    echo -e "${BLUE}Running: ${test_script}${NC}"
    echo -e "${BLUE}################################################################${NC}"
    
    # 运行测试并捕获退出码
    chmod +x "$test_path"
    
    # 重置测试计数器
    set +e
    bash "$test_path"
    TEST_EXIT_CODE=$?
    set -e
    
    if [ $TEST_EXIT_CODE -ne 0 ]; then
        FAILED_TESTS+=("$test_script")
    fi
done

# 打印最终摘要
echo ""
echo -e "${BLUE}################################################################${NC}"
echo -e "${BLUE}FINAL TEST SUMMARY${NC}"
echo -e "${BLUE}################################################################${NC}"

if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo -e "${GREEN}All test suites passed!${NC}"
    exit 0
else
    echo -e "${RED}Failed test suites:${NC}"
    for failed in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}- ${failed}${NC}"
    done
    exit 1
fi
