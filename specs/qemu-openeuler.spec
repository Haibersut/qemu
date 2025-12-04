%global debug_package %{nil}
%global _enable_debug_packages 0

# 禁用固件文件的 strip（它们不是 ELF 格式）
%global __os_install_post \
    /usr/lib/rpm/brp-compress \
%{nil}

Name:           qemu
Version:        9.0.1
Release:        1%{?dist}
Summary:        QEMU machine emulator and virtualizer
License:        GPLv2+ and BSD and MIT and CC-BY
URL:            https://www.qemu.org/
Source0:        https://download.qemu.org/qemu-%{version}.tar.xz

# 构建依赖
BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  make
BuildRequires:  ninja-build
BuildRequires:  meson
BuildRequires:  python3
BuildRequires:  python3-pip
BuildRequires:  flex
BuildRequires:  bison
BuildRequires:  diffutils
BuildRequires:  findutils
BuildRequires:  gettext

# 核心依赖
BuildRequires:  glib2-devel
BuildRequires:  pixman-devel
BuildRequires:  zlib-devel

# 推荐依赖
BuildRequires:  dtc
BuildRequires:  libfdt-devel
BuildRequires:  libaio-devel
BuildRequires:  libcap-ng-devel
BuildRequires:  libattr-devel
BuildRequires:  libseccomp-devel
BuildRequires:  numactl-devel
BuildRequires:  libcurl-devel
BuildRequires:  gnutls-devel
BuildRequires:  nettle-devel
BuildRequires:  cyrus-sasl-devel
BuildRequires:  libpng-devel
BuildRequires:  libjpeg-turbo-devel
BuildRequires:  ncurses-devel
BuildRequires:  libcap-devel
BuildRequires:  lzo-devel
BuildRequires:  snappy-devel
BuildRequires:  libssh-devel
BuildRequires:  libxml2-devel
BuildRequires:  systemd-devel
BuildRequires:  bzip2-devel
BuildRequires:  xz-devel
BuildRequires:  libzstd-devel
BuildRequires:  json-c-devel
BuildRequires:  libselinux-devel
BuildRequires:  pcre-devel
BuildRequires:  pcre2-devel

%description
QEMU is a generic and open source machine & userspace emulator and virtualizer.

This package provides QEMU with support for:
- x86_64 system emulation
- aarch64 system emulation
- x86_64 linux-user emulation
- aarch64 linux-user emulation

%prep
%setup -q -n qemu-%{version}

%build
# 根据构建主机确定目标架构
%ifarch x86_64
TARGETS="x86_64-softmmu,aarch64-softmmu,x86_64-linux-user,aarch64-linux-user"
%endif
%ifarch aarch64
TARGETS="aarch64-softmmu,x86_64-softmmu,aarch64-linux-user,x86_64-linux-user"
%endif

mkdir -p build
cd build

# 检查 libslirp 是否可用
SLIRP_OPT=""
if pkg-config --exists slirp 2>/dev/null; then
    SLIRP_OPT="--enable-slirp"
else
    SLIRP_OPT="--disable-slirp"
fi

# 配置 QEMU
../configure \
    --prefix=%{_prefix} \
    --sysconfdir=%{_sysconfdir} \
    --localstatedir=%{_localstatedir} \
    --libdir=%{_libdir} \
    --datadir=%{_datadir} \
    --docdir=%{_docdir}/qemu-%{version} \
    --target-list=${TARGETS} \
    --enable-kvm \
    ${SLIRP_OPT} \
    --enable-pie \
    --enable-linux-aio \
    --enable-cap-ng \
    --enable-attr \
    --enable-seccomp \
    --enable-vnc \
    --enable-vhost-net \
    --enable-vhost-user \
    --enable-linux-user \
    --enable-system \
    --enable-tools \
    --enable-guest-agent \
    --disable-debug-info \
    --disable-werror \
    || {
        # 如果完整配置失败，尝试最小配置
        echo "Full configuration failed, trying minimal configuration..."
        ../configure \
            --prefix=%{_prefix} \
            --sysconfdir=%{_sysconfdir} \
            --localstatedir=%{_localstatedir} \
            --libdir=%{_libdir} \
            --datadir=%{_datadir} \
            --docdir=%{_docdir}/qemu-%{version} \
            --target-list=${TARGETS} \
            --enable-kvm \
            ${SLIRP_OPT} \
            --enable-pie \
            --enable-vnc \
            --enable-linux-user \
            --enable-system \
            --enable-tools \
            --disable-debug-info \
            --disable-werror
    }

%make_build

%install
cd build
%make_install

# 创建便捷符号链接
%ifarch x86_64
ln -sf qemu-system-x86_64 %{buildroot}%{_bindir}/qemu
%endif
%ifarch aarch64
ln -sf qemu-system-aarch64 %{buildroot}%{_bindir}/qemu
%endif

# 创建配置目录
mkdir -p %{buildroot}%{_sysconfdir}/qemu
cat > %{buildroot}%{_sysconfdir}/qemu/bridge.conf << 'EOF'
# Bridge configuration for QEMU
# Add allowed bridges here, e.g.:
# allow br0
EOF

# 安装 udev 规则
mkdir -p %{buildroot}%{_prefix}/lib/udev/rules.d
cat > %{buildroot}%{_prefix}/lib/udev/rules.d/99-qemu-kvm.rules << 'EOF'
# KVM device permissions
KERNEL=="kvm", GROUP="kvm", MODE="0660"
EOF

%files
%license COPYING COPYING.LIB
%doc README.rst
%{_bindir}/qemu*
%{_bindir}/elf2dmp
%{_libexecdir}/qemu-bridge-helper
%{_libexecdir}/virtfs-proxy-helper
%{_datadir}/qemu/
%{_datadir}/applications/qemu.desktop
%{_datadir}/icons/hicolor/*/apps/qemu.*
%{_datadir}/locale/*/LC_MESSAGES/qemu.mo
%{_includedir}/qemu-plugin.h
%config(noreplace) %{_sysconfdir}/qemu/
%{_prefix}/lib/udev/rules.d/99-qemu-kvm.rules
%{_mandir}/man1/*
%{_mandir}/man7/*
%{_mandir}/man8/*
%{_docdir}/qemu-%{version}/

%post
# 添加 kvm 组（如果不存在）
getent group kvm >/dev/null || groupadd -r kvm || :

# 设置 bridge helper 权限
if [ -f %{_libexecdir}/qemu-bridge-helper ]; then
    chgrp kvm %{_libexecdir}/qemu-bridge-helper 2>/dev/null || :
    chmod 4750 %{_libexecdir}/qemu-bridge-helper 2>/dev/null || :
fi

# 重新加载 udev 规则
udevadm control --reload-rules 2>/dev/null || :
udevadm trigger 2>/dev/null || :

%changelog
* %(date "+%a %b %d %Y") QEMU Builder <builder@localhost> - %{version}-%{release}
- Build for openEuler
- Multi-architecture support (x86_64, aarch64)
