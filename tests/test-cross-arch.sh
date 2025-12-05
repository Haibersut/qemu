#!/bin/bash
# QEMU 跨架构测试
# 验证跨架构模拟器功能

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test-common.sh"

log_header "QEMU Cross-Architecture Tests"
log_info "Current Architecture: ${CURRENT_ARCH}"
log_info "QEMU Prefix: ${QEMU_PREFIX}"

# 确定跨架构目标
if [ "${CURRENT_ARCH}" = "x86_64" ]; then
    CROSS_ARCH="aarch64"
    CROSS_MACHINE="virt"
    CROSS_CPU="cortex-a57"
else
    CROSS_ARCH="x86_64"
    CROSS_MACHINE="q35"
    CROSS_CPU="qemu64"
fi

CROSS_QEMU_SYSTEM="${QEMU_PREFIX}/bin/qemu-system-${CROSS_ARCH}"

# ============================================================================
# 检查跨架构二进制是否存在
# ============================================================================

log_header "Cross-Architecture Binary Tests"

if [ ! -f "$CROSS_QEMU_SYSTEM" ]; then
    skip_test "qemu-system-${CROSS_ARCH} not found, skipping cross-arch tests"
    print_test_summary
    exit 0
fi

assert_file_exists "$CROSS_QEMU_SYSTEM" "qemu-system-${CROSS_ARCH} exists"
assert_file_executable "$CROSS_QEMU_SYSTEM" "qemu-system-${CROSS_ARCH} is executable"

# ============================================================================
# 测试跨架构版本
# ============================================================================

log_header "Cross-Architecture Version Tests"

CROSS_VERSION_OUTPUT=$(run_qemu "$CROSS_QEMU_SYSTEM" --version)
assert_not_empty "$CROSS_VERSION_OUTPUT" "Cross-arch QEMU version output is not empty"
assert_output_contains "QEMU emulator version" "$CROSS_VERSION_OUTPUT" "Cross-arch version output valid"

# ============================================================================
# 测试跨架构机器类型
# ============================================================================

log_header "Cross-Architecture Machine Tests"

CROSS_MACHINE_LIST=$(run_qemu "$CROSS_QEMU_SYSTEM" -machine help)
assert_not_empty "$CROSS_MACHINE_LIST" "Cross-arch machine list not empty"
assert_output_contains "$CROSS_MACHINE" "$CROSS_MACHINE_LIST" "Cross-arch machine type ${CROSS_MACHINE} available"

# ============================================================================
# 测试跨架构 CPU 类型
# ============================================================================

log_header "Cross-Architecture CPU Tests"

CROSS_CPU_LIST=$(run_qemu "$CROSS_QEMU_SYSTEM" -cpu help)
assert_not_empty "$CROSS_CPU_LIST" "Cross-arch CPU list not empty"
assert_output_contains "$CROSS_CPU" "$CROSS_CPU_LIST" "Cross-arch CPU type ${CROSS_CPU} available"

# ============================================================================
# 测试跨架构设备支持
# ============================================================================

log_header "Cross-Architecture Device Tests"

CROSS_DEVICE_LIST=$(run_qemu "$CROSS_QEMU_SYSTEM" -device help)
assert_output_contains "virtio-blk" "$CROSS_DEVICE_LIST" "Cross-arch virtio-blk supported"
assert_output_contains "virtio-net" "$CROSS_DEVICE_LIST" "Cross-arch virtio-net supported"

# ============================================================================
# 测试跨架构启动
# ============================================================================

log_header "Cross-Architecture Boot Tests"

TESTS_TOTAL=$((TESTS_TOTAL + 1))
log_info "Testing cross-architecture initialization..."

CROSS_BOOT_OUTPUT=$(timeout 3 "$CROSS_QEMU_SYSTEM" \
    -machine "$CROSS_MACHINE" \
    -cpu "$CROSS_CPU" \
    -m 128 \
    -smp 1 \
    -nographic \
    -monitor none \
    -serial none \
    -display none \
    -S \
    2>&1 &
    QEMU_PID=$!
    sleep 1
    if kill -0 $QEMU_PID 2>/dev/null; then
        kill $QEMU_PID 2>/dev/null
        wait $QEMU_PID 2>/dev/null
        echo "SUCCESS"
    else
        echo "EXITED"
    fi
)

if echo "$CROSS_BOOT_OUTPUT" | grep -qiE "(error|invalid|unknown)"; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    log_fail "Cross-architecture boot test failed"
    log_fail "Output: $CROSS_BOOT_OUTPUT"
else
    TESTS_PASSED=$((TESTS_PASSED + 1))
    log_pass "Cross-architecture initialization successful"
fi

# ============================================================================
# 打印测试结果
# ============================================================================

print_test_summary
