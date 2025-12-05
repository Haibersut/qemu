#!/bin/bash
# 构建 RPM 包

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/base.sh"
load_distro_config

INFO "Building RPM package..."

# 确保 rpmdevtools 已安装
check_command rpmbuild || {
    ERROR "rpmbuild not found, please install rpm-build and rpmdevtools"
    exit 1
}

# 设置 rpmbuild 目录
rpmdev-setuptree

RPMBUILD_DIR="${HOME}/rpmbuild"

# 下载源码到 SOURCES
WORKDIR "${RPMBUILD_DIR}/SOURCES"

tarball="${QEMU_SRC_BASENAME}.tar.xz"
if [ ! -f "${tarball}" ]; then
    INFO "Downloading QEMU source to SOURCES..."
    RUN wget -q "${QEMU_SRC_URL}" || {
        ERROR "Failed to download QEMU source"
        exit 1
    }
fi

# MD5 校验
if [ -n "${QEMU_SRC_MD5}" ]; then
    INFO "Verifying MD5 checksum..."
    actual_md5=$(md5sum "${tarball}" | awk '{print $1}')
    if [ "${actual_md5}" != "${QEMU_SRC_MD5}" ]; then
        ERROR "MD5 checksum verification failed!"
        ERROR "Expected: ${QEMU_SRC_MD5}"
        ERROR "Actual:   ${actual_md5}"
        rm -f "${tarball}"
        exit 1
    fi
    INFO "MD5 checksum verified successfully"
else
    WARN "No MD5 checksum provided, skipping verification"
fi

# 复制 spec 文件
SPEC_FILE=$(get_spec_file)
if [ ! -f "${SPEC_FILE}" ]; then
    ERROR "Spec file not found: ${SPEC_FILE}"
    exit 1
fi

INFO "Using spec file: ${SPEC_FILE}"
cp "${SPEC_FILE}" "${RPMBUILD_DIR}/SPECS/qemu.spec"

# 更新 spec 文件中的版本号
sed -i "s/^Version:.*/Version:        ${QEMU_VERSION}/" "${RPMBUILD_DIR}/SPECS/qemu.spec"

# 复制补丁文件
if [ -d "${WORK_ROOT}/patches" ]; then
    cp -v "${WORK_ROOT}/patches"/*.patch "${RPMBUILD_DIR}/SOURCES/" 2>/dev/null || true
fi

# 构建 RPM
INFO "Running rpmbuild..."
WORKDIR "${RPMBUILD_DIR}/SPECS"

RUN rpmbuild -bb qemu.spec \
    --define "_topdir ${RPMBUILD_DIR}" \
    --define "debug_package %{nil}" \
    --define "_build_name_fmt %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.${DISTRO}${DISTRO_VERSION}.rpm"

# 复制输出
mkdir -p "${OUTPUT_DIR}"

INFO "Contents of RPMS directory:"
ls -la "${RPMBUILD_DIR}/RPMS/" 2>/dev/null || true
find "${RPMBUILD_DIR}/RPMS" -name "*.rpm" -type f 2>/dev/null || true

INFO "Copying binary RPM packages to output directory..."
rpm_count=$(find "${RPMBUILD_DIR}/RPMS" -name "*.rpm" -type f 2>/dev/null | wc -l)
if [ "$rpm_count" -eq 0 ]; then
    ERROR "No RPM packages found in ${RPMBUILD_DIR}/RPMS"
    exit 1
fi

find "${RPMBUILD_DIR}/RPMS" -name "*.rpm" -type f -exec cp -v {} "${OUTPUT_DIR}/" \;
INFO "Copied ${rpm_count} RPM package(s) to output directory"

# 验证复制的文件
INFO "Verifying copied RPM packages..."
for rpm_file in "${OUTPUT_DIR}"/*.rpm; do
    if [ -f "$rpm_file" ]; then
        INFO "Package: $(basename "$rpm_file") - Size: $(du -h "$rpm_file" | cut -f1)"
        rpm -qpl "$rpm_file" 2>/dev/null | head -20 || true
    fi
done

# 重命名包含发行版信息
WORKDIR "${OUTPUT_DIR}"
for f in *.rpm; do
    if [[ -f "$f" && ! "$f" =~ "${DISTRO}" ]]; then
        newname=$(echo "$f" | sed "s/\.rpm$/.${DISTRO}${DISTRO_VERSION}.rpm/")
        mv "$f" "$newname" 2>/dev/null || true
    fi
done

INFO "RPM build completed successfully"
ls -la "${OUTPUT_DIR}/"
