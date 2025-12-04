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
    
    # 列出 artifacts 目录结构
    echo ""
    echo "Artifacts structure:"
    find artifacts -type f -name "*.rpm" -o -name "*.deb" | head -20
    
    # 复制所有 RPM 文件到 release 目录
    find artifacts -name "*.rpm" -exec cp {} release/ \;
    
    # 复制所有 DEB 文件到 release 目录
    find artifacts -name "*.deb" -exec cp {} release/ \;
    
    # 进入 release 目录
    cd release
    
    if [ "$(ls -A)" ]; then
        echo ""
        echo "Generating checksums..."
        
        # 生成 SHA256 校验和
        if ls *.rpm 1> /dev/null 2>&1; then
            sha256sum *.rpm > SHA256SUMS.txt
            echo "SHA256SUMS.txt generated for RPM files"
        fi
        
        if ls *.deb 1> /dev/null 2>&1; then
            sha256sum *.deb >> SHA256SUMS.txt
            echo "SHA256SUMS.txt updated with DEB files"
        fi
        
        # 生成 MD5 校验和
        if ls *.rpm 1> /dev/null 2>&1; then
            md5sum *.rpm > MD5SUMS.txt
            echo "MD5SUMS.txt generated for RPM files"
        fi
        
        if ls *.deb 1> /dev/null 2>&1; then
            md5sum *.deb >> MD5SUMS.txt
            echo "MD5SUMS.txt updated with DEB files"
        fi
        
        # 生成包信息文件
        echo ""
        echo "Generating package info..."
        {
            echo "# QEMU Build Packages"
            echo "# Generated at: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
            echo ""
            echo "## Package List"
            echo ""
            for f in *.rpm *.deb; do
                if [ -f "$f" ]; then
                    size=$(ls -lh "$f" | awk '{print $5}')
                    echo "- $f ($size)"
                fi
            done
        } > PACKAGES.md
    fi
    cd ..
else
    echo "WARNING: artifacts directory not found"
fi

# 列出 release 文件
echo ""
echo "=============================================="
echo "Release files:"
echo "=============================================="
ls -la release/

FILE_COUNT=$(ls release/ 2>/dev/null | wc -l)
echo ""
echo "Total files: ${FILE_COUNT}"
echo "=============================================="
