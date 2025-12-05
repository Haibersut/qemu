#!/bin/bash
# openEuler 22.03 LTS 发行版配置
# 此文件定义 openEuler 22.03 特有的配置

# Docker 镜像
DOCKER_IMAGE="openeuler/openeuler:22.03-lts"

# 包管理器
PKG_MANAGER="dnf"

# 基础构建依赖
BASE_BUILD_DEPS=(
    rpm-build
    rpmdevtools
    wget
    tar
    xz
    git
    make
    gcc
    gcc-c++
    ninja-build
    python3
    python3-pip
    meson
    flex
    bison
    diffutils
    findutils
    gettext
)

# QEMU 核心依赖
QEMU_CORE_DEPS=(
    glib2-devel
    pixman-devel
    zlib-devel
)

# QEMU 推荐依赖
QEMU_RECOMMENDED_DEPS=(
    dtc
    libfdt-devel
    libaio-devel
    libcap-ng-devel
    libattr-devel
    libseccomp-devel
    numactl-devel
    libcurl-devel
    gnutls-devel
    nettle-devel
    cyrus-sasl-devel
    libpng-devel
    libjpeg-turbo-devel
    ncurses-devel
    libcap-devel
    lzo-devel
    snappy-devel
    libssh-devel
    libxml2-devel
    systemd-devel
    bzip2-devel
    xz-devel
    libzstd-devel
    json-c-devel
    libselinux-devel
    pcre-devel
    pcre2-devel
    libslirp-devel
)

# QEMU 可选依赖
QEMU_OPTIONAL_DEPS=(
    SDL2-devel
    gtk3-devel
    libepoxy-devel
    virglrenderer-devel
    libusbx-devel
    usbredir-devel
    spice-server-devel
    spice-protocol
    libiscsi-devel
    libnfs-devel
    bluez-libs-devel
    librbd-devel
    librados-devel
)

# 可能不存在的依赖
QEMU_OPTIONAL_TRY_DEPS=(
    python3-sphinx
)

# 安装依赖函数
install_dependencies() {
    local pkg_mgr="${PKG_MANAGER}"
    
    INFO "Installing base build dependencies..."
    "${pkg_mgr}" install -y "${BASE_BUILD_DEPS[@]}"
    
    INFO "Installing QEMU core dependencies..."
    "${pkg_mgr}" install -y "${QEMU_CORE_DEPS[@]}"
    
    INFO "Installing QEMU recommended dependencies..."
    "${pkg_mgr}" install -y "${QEMU_RECOMMENDED_DEPS[@]}" || true
    
    INFO "Installing QEMU optional dependencies..."
    "${pkg_mgr}" install -y "${QEMU_OPTIONAL_DEPS[@]}" || true
    
    INFO "Trying to install optional dependencies..."
    for dep in "${QEMU_OPTIONAL_TRY_DEPS[@]}"; do
        "${pkg_mgr}" install -y "$dep" || WARN "Could not install $dep, skipping..."
    done
}

# QEMU configure 额外选项
get_configure_options() {
    local opts=""
    
    # 检查 libslirp 是否可用
    if pkg-config --exists slirp 2>/dev/null; then
        opts+=" --enable-slirp"
    else
        opts+=" --disable-slirp"
    fi
    
    echo "$opts"
}

# spec 文件路径
get_spec_file() {
    echo "${WORK_ROOT}/specs/qemu-openeuler.spec"
}
