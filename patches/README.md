# 补丁文件存放目录

将 QEMU 补丁文件 (`.patch`) 放在此目录中。

补丁会在构建过程中自动应用到 QEMU 源码。

## 补丁命名规范

建议使用以下命名格式：
```
NNNN-description.patch
```

其中 `NNNN` 是序号（如 0001, 0002），用于控制补丁应用顺序。

## 创建补丁

```bash
# 在 QEMU 源码目录中
git diff > /path/to/patches/0001-my-fix.patch

# 或者
git format-patch -1 HEAD --stdout > /path/to/patches/0001-my-fix.patch
```
