#!/bin/bash
# 准备 Release 文件
# 整理所有构建产物用于发布

set -e

echo "=============================================="
echo "Preparing Release Files"
echo "=============================================="

# 创建 release 目录
mkdir -p release

# 查找所有 artifacts
if [ -d "artifacts" ]; then
    echo "Found artifacts directory"
    
    # 复制所有 RPM 文件到 release 目录
    find artifacts -name "*.rpm" -exec cp {} release/ \;
    
    # 复制所有 DEB 文件到 release 目录
    find artifacts -name "*.deb" -exec cp {} release/ \;
    
    # 生成 checksums
    cd release
    if [ "$(ls -A)" ]; then
        echo "Generating checksums..."
        sha256sum *.rpm *.deb 2>/dev/null > SHA256SUMS.txt || true
        md5sum *.rpm *.deb 2>/dev/null > MD5SUMS.txt || true
    fi
    cd ..
else
    echo "WARNING: artifacts directory not found"
fi

# 列出 release 文件
echo ""
echo "Release files:"
ls -la release/

FILE_COUNT=$(ls release/ 2>/dev/null | wc -l)
echo ""
echo "Total files: ${FILE_COUNT}"
