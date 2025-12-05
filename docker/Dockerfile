# QEMU RPM 构建 Dockerfile
# 支持多架构和多发行版构建

ARG BASE_IMAGE=openeuler/openeuler:24.03-lts-sp2

FROM ${BASE_IMAGE}

# 构建参数
ARG QEMU_VERSION=9.0.1
ARG DISTRO=openeuler
ARG DISTRO_VERSION=24.03
ARG PACKAGE_TYPE=rpm

# 设置环境变量
ENV QEMU_VERSION=${QEMU_VERSION}
ENV DISTRO=${DISTRO}
ENV DISTRO_VERSION=${DISTRO_VERSION}
ENV PACKAGE_TYPE=${PACKAGE_TYPE}
ENV WORK_ROOT=/workspace

# 设置工作目录
WORKDIR /workspace

# 复制构建脚本和配置
COPY scripts/ /workspace/scripts/
COPY distros/ /workspace/distros/
COPY specs/ /workspace/specs/
COPY patches/ /workspace/patches/

# 设置脚本可执行权限并创建输出目录
RUN chmod +x /workspace/scripts/*.sh && \
    mkdir -p /workspace/output

# 默认运行 RPM 构建
CMD ["/workspace/scripts/build-rpm-all.sh"]
