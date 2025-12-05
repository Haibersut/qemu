#!/bin/bash
# 配置 QEMU 构建

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"
load_distro_config

INFO "Configuring QEMU build..."

# 确定目标架构
case "${HOST_ARCH}" in
    x86_64)
        TARGETS="x86_64-softmmu,aarch64-softmmu,x86_64-linux-user,aarch64-linux-user"
        ;;
    aarch64)
        TARGETS="aarch64-softmmu,x86_64-softmmu,aarch64-linux-user,x86_64-linux-user"
        ;;
    *)
        TARGETS="x86_64-softmmu,aarch64-softmmu"
        ;;
esac

INFO "Target list: ${TARGETS}"

# 创建构建目录
WORKDIR "${BUILD_DIR}/${QEMU_SRC_BASENAME}"

# 获取发行版特有的 configure 选项
DISTRO_OPTS=""
if type get_configure_options &>/dev/null; then
    DISTRO_OPTS=$(get_configure_options)
fi

# 自定义安装前缀
QEMU_PREFIX="/usr/local/qemu-${QEMU_VERSION}"

# 配置 QEMU
INFO "Running configure..."
INFO "Install prefix: ${QEMU_PREFIX}"
RUN "${SRC_DIR}/${QEMU_SRC_BASENAME}/configure" \
    --prefix="${QEMU_PREFIX}" \
    --sysconfdir="${QEMU_PREFIX}/etc" \
    --localstatedir="${QEMU_PREFIX}/var" \
    --libdir="${QEMU_PREFIX}/lib64" \
    --datadir="${QEMU_PREFIX}/share" \
    --docdir="${QEMU_PREFIX}/share/doc" \
    --target-list="${TARGETS}" \
    --enable-kvm \
    --enable-slirp \
    --enable-pie \
    --enable-linux-aio \
    --enable-cap-ng \
    --enable-attr \
    --enable-vnc \
    --enable-vhost-net \
    --enable-vhost-user \
    --enable-linux-user \
    --enable-system \
    --enable-tools \
    --enable-guest-agent \
    --enable-rbd \
    --enable-spice \
    ${DISTRO_OPTS}

INFO "Configure completed successfully"
