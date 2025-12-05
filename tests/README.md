# QEMU 构建测试

本目录包含 QEMU 构建后的验证测试脚本。

## 测试内容

测试脚本会验证以下内容：

### 1. 基础功能测试 (`test-basic.sh`)
- QEMU 二进制文件是否存在且可执行
- QEMU 版本信息是否正确
- QEMU 帮助信息是否正常输出
- QEMU 支持的 CPU 类型
- QEMU 支持的机器类型

### 2. 功能特性测试 (`test-features.sh`)
- 检查 QEMU 编译时启用的特性
- 验证关键设备支持（virtio、网络设备等）
- 检查模拟器后端支持

### 3. 快速启动测试 (`test-quick-boot.sh`)
- 无盘快速启动测试（验证 QEMU 可以正常初始化）
- 超时机制验证 QEMU 不会挂起

## 使用方法

### 运行所有测试
```bash
# 使用默认路径 /usr/local/qemu-9.0.1
./tests/run-all-tests.sh

# 或指定 QEMU 版本
QEMU_VERSION=9.0.1 ./tests/run-all-tests.sh

# 或指定完整路径
./tests/run-all-tests.sh /usr/local/qemu-9.0.1
```

### 运行单个测试
```bash
QEMU_VERSION=9.0.1 ./tests/test-basic.sh
# 或
QEMU_PREFIX=/usr/local/qemu-9.0.1 ./tests/test-basic.sh
```

## 测试矩阵

| 发行版 | 版本 | amd64 | arm64 |
|--------|------|-------|-------|
| openEuler | 22.03 | ✓ | ✓ |
| openEuler | 24.03 | ✓ | ✓ |

## 添加新测试

1. 在 `tests/` 目录下创建新的测试脚本 `test-xxx.sh`
2. 使用 `test-common.sh` 中的辅助函数
3. 在 `run-all-tests.sh` 中添加新测试
