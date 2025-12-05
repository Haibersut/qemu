#!/bin/bash
# QEMU 功能特性测试
# 验证 QEMU 编译时启用的功能和设备支持

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/test-common.sh"

log_header "QEMU Feature Tests"
log_info "Architecture: ${CURRENT_ARCH}"
log_info "QEMU Prefix: ${QEMU_PREFIX}"

QEMU_SYSTEM=$(get_qemu_system)

# ============================================================================
# 测试存储后端支持
# ============================================================================

log_header "Storage Backend Tests"

DEVICE_LIST=$(run_qemu "$QEMU_SYSTEM" -device help)

# Virtio 存储设备
assert_output_contains "virtio-blk-pci" "$DEVICE_LIST" "virtio-blk-pci device supported"
assert_output_contains "virtio-scsi-pci" "$DEVICE_LIST" "virtio-scsi-pci device supported"

# SCSI 设备
assert_output_contains "scsi-hd" "$DEVICE_LIST" "scsi-hd device supported"
assert_output_contains "scsi-cd" "$DEVICE_LIST" "scsi-cd device supported"

# IDE 设备（主要用于 x86）
if [ "${CURRENT_ARCH}" = "x86_64" ]; then
    assert_output_contains "ide-hd" "$DEVICE_LIST" "ide-hd device supported"
    assert_output_contains "ide-cd" "$DEVICE_LIST" "ide-cd device supported"
fi

# NVMe 设备
assert_output_contains "nvme" "$DEVICE_LIST" "nvme device supported"

# ============================================================================
# 测试网络设备支持
# ============================================================================

log_header "Network Device Tests"

# Virtio 网络
assert_output_contains "virtio-net-pci" "$DEVICE_LIST" "virtio-net-pci device supported"

# e1000 网卡
assert_output_contains "e1000" "$DEVICE_LIST" "e1000 device supported"

# ============================================================================
# 测试显示设备支持
# ============================================================================

log_header "Display Device Tests"

# VGA 设备（主要用于 x86）
if [ "${CURRENT_ARCH}" = "x86_64" ]; then
    assert_output_contains "VGA" "$DEVICE_LIST" "VGA device supported"
    assert_output_contains "qxl" "$DEVICE_LIST" "qxl device supported" || skip_test "qxl may not be built"
fi

# virtio-gpu
assert_output_contains "virtio-gpu" "$DEVICE_LIST" "virtio-gpu device supported"

# ============================================================================
# 测试 USB 设备支持
# ============================================================================

log_header "USB Device Tests"

# USB 控制器
assert_output_contains "usb-ehci" "$DEVICE_LIST" "usb-ehci controller supported" || \
    assert_output_contains "qemu-xhci" "$DEVICE_LIST" "qemu-xhci controller supported"

# USB 设备
assert_output_contains "usb-tablet" "$DEVICE_LIST" "usb-tablet device supported"
assert_output_contains "usb-kbd" "$DEVICE_LIST" "usb-kbd device supported"
assert_output_contains "usb-mouse" "$DEVICE_LIST" "usb-mouse device supported"
assert_output_contains "usb-storage" "$DEVICE_LIST" "usb-storage device supported"

# ============================================================================
# 测试串口和字符设备
# ============================================================================

log_header "Character Device Tests"

CHARDEV_OUTPUT=$(run_qemu "$QEMU_SYSTEM" -chardev help)
assert_output_contains "socket" "$CHARDEV_OUTPUT" "socket chardev supported"
assert_output_contains "file" "$CHARDEV_OUTPUT" "file chardev supported"
assert_output_contains "stdio" "$CHARDEV_OUTPUT" "stdio chardev supported"
assert_output_contains "pty" "$CHARDEV_OUTPUT" "pty chardev supported"
assert_output_contains "null" "$CHARDEV_OUTPUT" "null chardev supported"

# ============================================================================
# 测试音频后端
# ============================================================================

log_header "Audio Backend Tests"

AUDIO_OUTPUT=$(run_qemu "$QEMU_SYSTEM" -audio help 2>&1 || true)
if echo "$AUDIO_OUTPUT" | grep -q "none"; then
    log_pass "Audio backends available"
else
    skip_test "Audio backends may not be configured"
fi

# ============================================================================
# 测试网络后端
# ============================================================================

log_header "Network Backend Tests"

NETDEV_OUTPUT=$(run_qemu "$QEMU_SYSTEM" -netdev help)
assert_output_contains "user" "$NETDEV_OUTPUT" "user netdev supported"
assert_output_contains "tap" "$NETDEV_OUTPUT" "tap netdev supported"
assert_output_contains "socket" "$NETDEV_OUTPUT" "socket netdev supported"

# ============================================================================
# 测试块设备驱动
# ============================================================================

log_header "Block Driver Tests"

# 通过 qemu-img 检查格式支持
QEMU_IMG="${QEMU_PREFIX}/bin/qemu-img"
FORMAT_OUTPUT=$("$QEMU_IMG" --help 2>&1 || true)

# 基础格式
assert_output_contains "qcow2" "$FORMAT_OUTPUT" "qcow2 format supported"
assert_output_contains "raw" "$FORMAT_OUTPUT" "raw format supported"
assert_output_contains "vmdk" "$FORMAT_OUTPUT" "vmdk format supported" || skip_test "vmdk format optional"
assert_output_contains "vpc" "$FORMAT_OUTPUT" "vpc (VHD) format supported" || skip_test "vpc format optional"
assert_output_contains "vdi" "$FORMAT_OUTPUT" "vdi format supported" || skip_test "vdi format optional"

# ============================================================================
# 测试 QEMU Monitor
# ============================================================================

log_header "Monitor Tests"

# 检查 monitor 相关命令行参数
HELP_OUTPUT=$(run_qemu "$QEMU_SYSTEM" --help)
assert_output_contains "-monitor" "$HELP_OUTPUT" "-monitor option available"
assert_output_contains "-qmp" "$HELP_OUTPUT" "-qmp option available" || skip_test "QMP may not be displayed in help"

# ============================================================================
# 测试加速器支持
# ============================================================================

log_header "Accelerator Tests"

ACCEL_OUTPUT=$(run_qemu "$QEMU_SYSTEM" -accel help)
assert_output_contains "tcg" "$ACCEL_OUTPUT" "tcg accelerator supported"

# KVM 支持检测（可能需要 root 权限）
if echo "$ACCEL_OUTPUT" | grep -q "kvm"; then
    log_pass "kvm accelerator built-in"
else
    skip_test "kvm accelerator not built or not shown"
fi

# ============================================================================
# 测试 Object 类型
# ============================================================================

log_header "Object Type Tests"

OBJECT_OUTPUT=$(run_qemu "$QEMU_SYSTEM" -object help)
assert_output_contains "iothread" "$OBJECT_OUTPUT" "iothread object supported"
assert_output_contains "memory-backend-file" "$OBJECT_OUTPUT" "memory-backend-file object supported"

# ============================================================================
# 打印测试结果
# ============================================================================

print_test_summary
