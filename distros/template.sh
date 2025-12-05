#!/bin/bash
# 发行版配置模板
# 复制此文件并修改以支持新的发行版
# 文件命名格式: <distro>-<version>.sh

# Docker 镜像
DOCKER_IMAGE="your-distro/image:version"

# 包管理器: dnf, yum, apt, apk
PKG_MANAGER="dnf"

# 包类型: rpm 或 deb
PACKAGE_TYPE="rpm"

# 基础构建依赖
BASE_BUILD_DEPS=(
    # 构建工具
    make
    gcc
    gcc-c++
    # ... 添加更多依赖
)

# QEMU 核心依赖
QEMU_CORE_DEPS=(
    glib2-devel
    pixman-devel
    zlib-devel
)

# QEMU 推荐依赖
QEMU_RECOMMENDED_DEPS=(
    # 添加推荐依赖
)

# QEMU 可选依赖
QEMU_OPTIONAL_DEPS=(
    # 添加可选依赖
)

# 可能不存在的依赖（尝试安装）
QEMU_OPTIONAL_TRY_DEPS=(
    # 添加可能不存在的依赖
)

# 安装依赖函数
install_dependencies() {
    local pkg_mgr="${PKG_MANAGER}"
    
    INFO "Installing dependencies for ${DISTRO}-${DISTRO_VERSION}..."
    
    # 根据包管理器类型安装
    case "$pkg_mgr" in
        dnf|yum)
            "${pkg_mgr}" install -y "${BASE_BUILD_DEPS[@]}"
            "${pkg_mgr}" install -y "${QEMU_CORE_DEPS[@]}"
            "${pkg_mgr}" install -y "${QEMU_RECOMMENDED_DEPS[@]}" || true
            "${pkg_mgr}" install -y "${QEMU_OPTIONAL_DEPS[@]}" || true
            ;;
        apt)
            apt-get update
            apt-get install -y "${BASE_BUILD_DEPS[@]}"
            apt-get install -y "${QEMU_CORE_DEPS[@]}"
            apt-get install -y "${QEMU_RECOMMENDED_DEPS[@]}" || true
            apt-get install -y "${QEMU_OPTIONAL_DEPS[@]}" || true
            ;;
        apk)
            apk update
            apk add "${BASE_BUILD_DEPS[@]}"
            apk add "${QEMU_CORE_DEPS[@]}"
            apk add "${QEMU_RECOMMENDED_DEPS[@]}" || true
            apk add "${QEMU_OPTIONAL_DEPS[@]}" || true
            ;;
    esac
    
    for dep in "${QEMU_OPTIONAL_TRY_DEPS[@]}"; do
        "${pkg_mgr}" install -y "$dep" 2>/dev/null || true
    done
}

# QEMU configure 额外选项
get_configure_options() {
    local opts=""
    # 添加发行版特有的 configure 选项
    echo "$opts"
}

# spec/control 文件路径
get_spec_file() {
    case "$PACKAGE_TYPE" in
        rpm)
            echo "${WORK_ROOT}/specs/qemu-${DISTRO}.spec"
            ;;
        deb)
            echo "${WORK_ROOT}/debian/control"
            ;;
    esac
}
