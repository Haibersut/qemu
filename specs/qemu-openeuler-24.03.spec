%global debug_package %{nil}
%global _enable_debug_packages 0

# 自定义安装前缀
%global qemu_prefix /usr/local/qemu-%{version}

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
BuildRequires:  libslirp-devel
BuildRequires:  spice-server-devel
BuildRequires:  spice-protocol
BuildRequires:  librbd-devel
BuildRequires:  librados-devel

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
%ifarch x86_64
TARGETS="x86_64-softmmu,aarch64-softmmu,x86_64-linux-user,aarch64-linux-user"
%endif
%ifarch aarch64
TARGETS="aarch64-softmmu,x86_64-softmmu,aarch64-linux-user,x86_64-linux-user"
%endif

mkdir -p build
cd build

# 配置 QEMU
../configure \
    --prefix=%{qemu_prefix} \
    --sysconfdir=%{qemu_prefix}/etc \
    --localstatedir=%{qemu_prefix}/var \
    --libdir=%{qemu_prefix}/lib64 \
    --datadir=%{qemu_prefix}/share \
    --docdir=%{qemu_prefix}/share/doc \
    --target-list=${TARGETS} \
    --enable-kvm \
    --enable-slirp \
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
    --enable-rbd \
    --enable-spice \

%make_build

%install
cd build
%make_install

# 创建便捷符号链接
%ifarch x86_64
ln -sf qemu-system-x86_64 %{buildroot}%{qemu_prefix}/bin/qemu
%endif
%ifarch aarch64
ln -sf qemu-system-aarch64 %{buildroot}%{qemu_prefix}/bin/qemu
%endif

# 安装 udev 规则到系统目录
mkdir -p %{buildroot}/usr/lib/udev/rules.d
cat > %{buildroot}/usr/lib/udev/rules.d/99-qemu-kvm.rules << 'EOF'
# KVM device permissions
KERNEL=="kvm", GROUP="kvm", MODE="0660"
EOF

%files
%license COPYING COPYING.LIB
%doc README.rst
%{qemu_prefix}/
/usr/lib/udev/rules.d/99-qemu-kvm.rules

%post
getent group kvm >/dev/null || groupadd -r kvm || :

# 设置 bridge helper 权限
if [ -f %{qemu_prefix}/libexec/qemu-bridge-helper ]; then
    chgrp kvm %{qemu_prefix}/libexec/qemu-bridge-helper 2>/dev/null || :
    chmod 4750 %{qemu_prefix}/libexec/qemu-bridge-helper 2>/dev/null || :
fi

# 重新加载 udev 规则
udevadm control --reload-rules 2>/dev/null || :
udevadm trigger 2>/dev/null || :

%changelog
* Fri Dec 05 2025 QEMU Builder <builder@haibersut.com> - 9.0.1-1
- Initial package for openEuler 24.03
- Multi-architecture support (x86_64, aarch64)
- Enable KVM virtualization
- Enable SPICE remote display
- Enable Ceph RBD storage backend
- Enable linux-user emulation
