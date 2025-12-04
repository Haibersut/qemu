# QEMU Multi-Architecture RPM Builder

使用 GitHub Actions 和 Docker buildx 构建多架构 (amd64/aarch64) 的 QEMU RPM 包。

## 功能特性

- **多架构支持**: 同时构建 amd64 和 aarch64 架构
- **多发行版支持**: 支持 openEuler 22.03 和 24.03 LTS
- **RPM 包构建**: 生成标准的 RPM 软件包
- **可扩展设计**: 易于添加新的发行版支持
- **CI/CD 集成**: 完整的 GitHub Actions 工作流

## 目录结构

```
qemu/
├── .github/
│   ├── workflows/
│   │   └── build.yml          # GitHub Actions 工作流
│   └── scripts/
│       ├── generate-matrix.sh  # 生成构建矩阵
│       ├── prepare-build.sh    # 准备构建环境
│       ├── build-package.sh    # 执行构建
│       └── prepare-release.sh  # 准备发布文件
├── distros/
│   ├── openeuler-22.03.sh     # openEuler 22.03 配置
│   ├── openeuler-24.03.sh     # openEuler 24.03 配置
│   └── template.sh            # 发行版配置模板
├── docker/
│   ├── Dockerfile             # 构建镜像定义
│   └── build.sh               # 本地构建脚本
├── patches/                   # QEMU 补丁文件（可选）
├── scripts/
│   ├── base.sh                # 基础变量和函数
│   ├── fetch.sh               # 下载源码
│   ├── extract.sh             # 解压源码
│   ├── patch.sh               # 应用补丁
│   ├── configure.sh           # 配置构建
│   ├── build.sh               # 编译
│   ├── install.sh             # 安装
│   ├── install-deps.sh        # 安装依赖
│   ├── build-rpm.sh           # 构建 RPM
│   ├── build-all.sh           # 完整构建（二进制）
│   └── build-rpm-all.sh       # 完整构建（RPM）
├── specs/
│   └── qemu-openeuler.spec    # openEuler RPM spec 文件
└── README.md
```

## 使用方法

### GitHub Actions 自动构建

1. Fork 或克隆此仓库
2. 推送到 `main` 或 `master` 分支会自动触发构建
3. 创建 tag (如 `v9.0.1`) 会触发构建并创建 Release

### 手动触发构建

1. 进入 GitHub 仓库的 Actions 页面
2. 选择 "Build QEMU RPM Packages" 工作流
3. 点击 "Run workflow"
4. 可选：指定 QEMU 版本和目标发行版

### 本地构建

```bash
# 使用默认配置构建 (openEuler 24.03, 当前架构)
./docker/build.sh

# 指定版本和发行版
./docker/build.sh --qemu-version 9.0.1 --distro openeuler --distro-version 22.03

# 构建 aarch64 架构 (需要 QEMU 用户空间模拟)
./docker/build.sh --arch aarch64
```

## 添加新发行版支持

1. 在 `distros/` 目录创建新的配置文件，参考 `template.sh`
2. 如需要，在 `specs/` 目录创建对应的 spec 文件
3. 更新 `.github/scripts/build-package.sh` 中的 BASE_IMAGE 映射

### 配置文件示例

```bash
# distros/your-distro-version.sh

# Docker 镜像
DOCKER_IMAGE="your-distro/image:version"

# 包管理器
PKG_MANAGER="dnf"

# 构建依赖数组
BASE_BUILD_DEPS=(...)
QEMU_CORE_DEPS=(...)
QEMU_RECOMMENDED_DEPS=(...)

# 安装依赖函数
install_dependencies() {
    # 实现依赖安装
}

# configure 选项函数
get_configure_options() {
    echo "--enable-xxx"
}
```

## 环境变量

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `QEMU_VERSION` | QEMU 版本 | 9.0.1 |
| `DISTRO` | 发行版名称 | openeuler |
| `DISTRO_VERSION` | 发行版版本 | 24.03 |
| `PACKAGE_TYPE` | 包类型 (rpm/deb) | rpm |
| `WORK_ROOT` | 工作目录 | /workspace |

## 构建产物

构建完成后，RPM 包将位于 `output/<distro>-<version>/<arch>/` 目录。

示例：
```
output/
├── openeuler-22.03/
│   ├── x86_64/
│   │   └── qemu-9.0.1-1.x86_64.openeuler22.03.rpm
│   └── aarch64/
│       └── qemu-9.0.1-1.aarch64.openeuler22.03.rpm
└── openeuler-24.03/
    ├── x86_64/
    │   └── qemu-9.0.1-1.x86_64.openeuler24.03.rpm
    └── aarch64/
        └── qemu-9.0.1-1.aarch64.openeuler24.03.rpm
```

## 故障排除

### 构建失败

1. 检查 GitHub Actions 日志中的错误信息
2. 确认发行版配置文件中的依赖包名称正确
3. 某些依赖可能在特定版本中不存在，会被自动跳过

### 本地构建问题

1. 确保已安装 Docker 和 Docker Buildx
2. 跨架构构建需要启用 QEMU 用户空间模拟：
   ```bash
   docker run --privileged --rm tonistiigi/binfmt --install all
   ```

## 许可证

本项目采用与 QEMU 相同的许可证。

## 贡献

欢迎提交 Pull Request 添加新发行版支持或改进构建流程！
