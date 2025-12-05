#!/bin/bash
# QEMU 基础功能测试
# 验证 QEMU 二进制文件和基本功能

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test-common.sh"

log_header "QEMU Basic Tests"
log_info "Architecture: ${CURRENT_ARCH}"
log_info "QEMU Prefix: ${QEMU_PREFIX}"

# ============================================================================
# 测试 QEMU 二进制文件
# ============================================================================

log_header "Binary File Tests"

# 测试 qemu-system 二进制
QEMU_SYSTEM=$(get_qemu_system)
assert_file_exists "$QEMU_SYSTEM" "qemu-system-${CURRENT_ARCH} exists"
assert_file_executable "$QEMU_SYSTEM" "qemu-system-${CURRENT_ARCH} is executable"

# 测试 qemu-img
QEMU_IMG="${QEMU_PREFIX}/bin/qemu-img"
assert_file_exists "$QEMU_IMG" "qemu-img exists"
assert_file_executable "$QEMU_IMG" "qemu-img is executable"

# 测试跨架构 qemu-system（可选）
if [ "${CURRENT_ARCH}" = "x86_64" ]; then
    CROSS_QEMU="${QEMU_PREFIX}/bin/qemu-system-aarch64"
else
    CROSS_QEMU="${QEMU_PREFIX}/bin/qemu-system-x86_64"
fi

if [ -f "$CROSS_QEMU" ]; then
    assert_file_executable "$CROSS_QEMU" "Cross-architecture QEMU binary is executable"
else
    skip_test "Cross-architecture QEMU binary not found (optional)"
fi

# ============================================================================
# 测试 QEMU 版本
# ============================================================================

log_header "Version Tests"

VERSION_OUTPUT=$(run_qemu "$QEMU_SYSTEM" --version)
assert_not_empty "$VERSION_OUTPUT" "QEMU version output is not empty"
assert_output_contains "QEMU emulator version" "$VERSION_OUTPUT" "Version output contains expected string"

# 提取版本号
QEMU_VERSION=$(echo "$VERSION_OUTPUT" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
assert_not_empty "$QEMU_VERSION" "Can extract QEMU version number"
log_info "Detected QEMU version: $QEMU_VERSION"

# qemu-img 版本
IMG_VERSION_OUTPUT=$(run_qemu "$QEMU_IMG" --version)
assert_not_empty "$IMG_VERSION_OUTPUT" "qemu-img version output is not empty"
assert_output_contains "qemu-img version" "$IMG_VERSION_OUTPUT" "qemu-img version output contains expected string"

# ============================================================================
# 测试 QEMU 帮助信息
# ============================================================================

log_header "Help Output Tests"

HELP_OUTPUT=$(run_qemu "$QEMU_SYSTEM" --help)
assert_not_empty "$HELP_OUTPUT" "QEMU help output is not empty"
assert_output_contains "-machine" "$HELP_OUTPUT" "Help contains -machine option"
assert_output_contains "-cpu" "$HELP_OUTPUT" "Help contains -cpu option"
assert_output_contains "-m" "$HELP_OUTPUT" "Help contains -m (memory) option"
assert_output_contains "-smp" "$HELP_OUTPUT" "Help contains -smp option"
assert_output_contains "-drive" "$HELP_OUTPUT" "Help contains -drive option"
assert_output_contains "-device" "$HELP_OUTPUT" "Help contains -device option"
assert_output_contains "-netdev" "$HELP_OUTPUT" "Help contains -netdev option"

# ============================================================================
# 测试 CPU 列表
# ============================================================================

log_header "CPU Support Tests"

CPU_LIST=$(run_qemu "$QEMU_SYSTEM" -cpu help)
assert_not_empty "$CPU_LIST" "CPU list is not empty"

# 检查当前架构的关键 CPU 类型
if [ "${CURRENT_ARCH}" = "x86_64" ]; then
    assert_output_contains "qemu64" "$CPU_LIST" "CPU list contains qemu64"
    assert_output_contains "host" "$CPU_LIST" "CPU list contains host" || skip_test "host CPU type may require KVM"
else
    assert_output_contains "cortex-a57" "$CPU_LIST" "CPU list contains cortex-a57"
    assert_output_contains "cortex-a72" "$CPU_LIST" "CPU list contains cortex-a72"
fi

# ============================================================================
# 测试机器类型
# ============================================================================

log_header "Machine Type Tests"

MACHINE_LIST=$(run_qemu "$QEMU_SYSTEM" -machine help)
assert_not_empty "$MACHINE_LIST" "Machine list is not empty"

if [ "${CURRENT_ARCH}" = "x86_64" ]; then
    assert_output_contains "q35" "$MACHINE_LIST" "Machine list contains q35"
    assert_output_contains "pc" "$MACHINE_LIST" "Machine list contains pc"
else
    assert_output_contains "virt" "$MACHINE_LIST" "Machine list contains virt"
fi

# ============================================================================
# 测试设备列表
# ============================================================================

log_header "Device Support Tests"

DEVICE_LIST=$(run_qemu "$QEMU_SYSTEM" -device help)
assert_not_empty "$DEVICE_LIST" "Device list is not empty"

# 检查关键虚拟设备
assert_output_contains "virtio-blk" "$DEVICE_LIST" "Device list contains virtio-blk"
assert_output_contains "virtio-net" "$DEVICE_LIST" "Device list contains virtio-net"
assert_output_contains "virtio-scsi" "$DEVICE_LIST" "Device list contains virtio-scsi"

# ============================================================================
# 测试磁盘镜像格式支持
# ============================================================================

log_header "qemu-img Format Tests"

FORMAT_OUTPUT=$("$QEMU_IMG" --help 2>&1 || true)
assert_output_contains "qcow2" "$FORMAT_OUTPUT" "qemu-img supports qcow2 format"
assert_output_contains "raw" "$FORMAT_OUTPUT" "qemu-img supports raw format"

# 创建临时镜像测试
TEMP_IMG=$(mktemp --suffix=.qcow2)
trap "rm -f $TEMP_IMG" EXIT

CREATE_OUTPUT=$("$QEMU_IMG" create -f qcow2 "$TEMP_IMG" 1G 2>&1)
assert_true "[ -f '$TEMP_IMG' ]" "qemu-img can create qcow2 image"

INFO_OUTPUT=$("$QEMU_IMG" info "$TEMP_IMG" 2>&1)
assert_output_contains "file format: qcow2" "$INFO_OUTPUT" "qemu-img info shows correct format"
assert_output_contains "virtual size: 1 GiB" "$INFO_OUTPUT" "qemu-img info shows correct size"

# ============================================================================
# 打印测试结果
# ============================================================================

print_test_summary
